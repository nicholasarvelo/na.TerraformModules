locals {
  # By default, EC2 instances employ the most recent Amazon Linux 2023  AMI.
  # However, if an AMI ID is provided, it overrides this default selection.
  ami_id_provided = var.ami_id != null
  ami_id          = local.ami_id_provided ? var.ami_id : data.aws_ami.this.id

  # An instance profile is an IAM role that is attached to an EC2 instance.
  instance_profile_name = (
    format("%sHostRole", title(var.hostname))
  )
}

locals {
  instance_name = {
    Name = var.hostname
  }

  resource_tags = {
    Function = var.function
  }
}

# Terraform is set up to automatically pick a subnet for the IDE Host, as we
# have no specific location preference. This is done using the 'random_integer'
# resource. This resource creates a random value and sticks to it, only
# generating a new number if changes are detected in the 'keepers' map. By doing
# this, we avoid unnecessary recreations of the IDE host. Using the EC2's
# immobility across AWS regions as a trigger ensures consistency in this random
# choice.
resource "random_integer" "subnet_id_index" {
  max = length(data.aws_subnets.this.ids) - 1
  min = 0
  keepers = {
    aws_region = var.aws_region
  }
}

locals {
  # Determines if the load balancer to provision is internal or external. This
  # impacts the which network related resources are provisioned and how.
  internal_load_balancer = (
    var.load_balancer_scheme == "internet-facing" ? false : true
  )

  subnet_type = local.internal_load_balancer ? "private" : "public"

  subnet_name_search_filter = (
    format("%s-%s-*", var.vpc_name, local.subnet_type)
  )

  random_subnet_id = (
    data.aws_subnets.this.ids[random_integer.subnet_id_index.result]
  )

  route53_zone_ids = toset([data.aws_route53_zone.this.id])

  key_name = (
    var.import_key_pair ?
    var.key_pair["key_name"] :
    data.aws_key_pair.this[0].key_name
  )
}

# Imports an existing key pair for use with ssh authentication.
resource "aws_key_pair" "this" {
  count      = var.import_key_pair ? 1 : 0
  key_name   = var.key_pair["key_name"]
  public_key = var.key_pair["public_key"]
}

# This resource block defines the AWS EC2 instance.
resource "aws_instance" "this" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  key_name                    = local.key_name
  subnet_id                   = local.random_subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name

  root_block_device {
    encrypted   = true
    iops        = var.root_volume_iops
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }
  tags = merge(local.resource_tags, local.instance_name)
}

# This resource block establishes an IAM role specifically for EC2 instances,
# allowing them to make API calls on behalf of a user. It eliminates the need
# for directly embedding AWS access keys.
resource "aws_iam_role" "this" {
  name = local.instance_profile_name
  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com",
          ]
        }
      },
    ]
    Version = "2012-10-17"
  })

  managed_policy_arns = var.iam_role_managed_policy_arns

  tags = local.resource_tags
}

# This resource provisions an AWS IAM instance profile using the same name as
# the IAM role created above. An instance profile is a container for an AWS IAM
# role that can be used to pass the role information to an EC2 instance at
# launch time.
resource "aws_iam_instance_profile" "this" {
  name = aws_iam_role.this.name
  role = aws_iam_role.this.name
}

# This resource block is setting up an attachment between an EC2 instance
# (target) and a load balancer target group. It's enabling the load balancer to
# route traffic to that EC2 instance on port 22 (SSH).
resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = aws_instance.this.id
  port             = 22
}

# This resource block creates an AWS Load Balancer. We use this load balancer
# when connecting to a bastion host.
resource "aws_lb" "this" {
  internal           = local.internal_load_balancer
  load_balancer_type = var.load_balancer_type
  subnets            = [for subnet in data.aws_subnet.this : subnet.id]

  tags = local.resource_tags
}

# This resource block creates an AWS Load Balancer Listener for the load
# balancer defined above. A listener waits for incoming connections on the
# specified port and protocol, and forwards the connections to the
# corresponding target group.
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.load_balancer_listener_port
  protocol          = var.load_balancer_listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = local.resource_tags
}

# This resource block creates a target group which listens on the defined port
# and protocol to route requests from the load balancer to registered targets
# (EC2 instances in this case).
resource "aws_lb_target_group" "this" {
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = data.aws_vpc.this.id

  health_check {
    protocol = var.target_group_protocol
  }

  tags = local.resource_tags
}

# This resource block creates an AWS Route53 DNS Alias record that points to
# the load balancer's DNS name in the specified Route53 Zone. We're using an
# alias record because it points directly to an AWS resource instead of an ip
# address. A benefit of this is that it can automatically recognize changes
# in the IP addresses of the target AWS resource freeing us from having to
# worry about updating static DNS records.
resource "aws_route53_record" "this" {
  for_each = local.route53_zone_ids
  name     = var.hostname
  type     = "A"
  zone_id  = each.value

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

# This resource block creates an AWS security group that is attached to any EC2
# instance created within the auto scaling group. The association to EC2
# instances is orchestrated by the AWS launch template.
resource "aws_security_group" "this" {
  vpc_id = data.aws_vpc.this.id

  tags = local.resource_tags

  lifecycle {
    create_before_destroy = true
  }
}

# This resource block creates an inbound rule for the AWS security group
# restricting inbound traffic to only those sources originating from within the
# VPC the EC2 instance resides. This ingress rule allows Target Group health
# checks to work.
# To allow additional inbound traffic, we to create additional
# 'aws_vpc_security_group_ingress_rule' resources in the root module.
resource "aws_vpc_security_group_ingress_rule" "vpc" {
  description       = "Allows target group health checks."
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = data.aws_vpc.this.cidr_block
  from_port   = var.target_group_port
  ip_protocol = var.target_group_protocol
  to_port     = var.target_group_port

  tags = local.resource_tags
}

# This resource block creates an outbound rule for the AWS security group.
resource "aws_vpc_security_group_egress_rule" "this" {
  description       = "This rule permits all outgoing traffic."
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = local.resource_tags
}
