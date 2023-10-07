# Retrieves the latest Amazon Linux 2023 (AL2023) Amazon Machine Image (AMI).
data "aws_ami" "this" {
  owners      = var.ami_owner
  most_recent = true

  filter {
    name   = "name"
    values = var.ami_name_filter
  }

  filter {
    name   = "architecture"
    values = [var.ami_architecture]
  }
}

data "aws_key_pair" "this" {
  count    = var.import_key_pair ? 0 : 1
  key_name = var.key_pair["key_name"]
}


# Retrieves details about the specified public Amazon Route 53 hosted zone. This
# zone's attributes are needed to create the DNS record we will use when
# connecting (via ssh) to an Amazon EC2 instance.
data "aws_route53_zone" "this" {
  name = var.route53_zone_name
}

# Loops through the list of subnets creating a data source object for each
# subnet. This is used to populate a list of subnets to associate with the
# load balancer.
data "aws_subnet" "this" {
  for_each = toset(data.aws_subnets.this.ids)
  id       = each.value
}

# Generates a list of all subnets associated to the specific VPC ID. The list
# is then further filtered to only show subnets with name tags prefixed with
# the value of 'local.subnet_name_search_filter'.
data "aws_subnets" "this" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  tags = {
    Name = local.subnet_name_search_filter
  }
}

# Retrieves details about a specific VPC. The information obtained is then used
# in other data sources to query other VPC-related resources such as subnets.
data "aws_vpc" "this" {
  tags = {
    Name = var.vpc_name
  }
}
