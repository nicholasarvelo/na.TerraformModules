variable "ami_architecture" {
  type        = string
  description = "(Required) The architecture of the Amazon Machine Image (AMI) that will be used to deploy an EC2 instance. The valid architecture options are 'arm64' and 'x86_64'."
}

variable "ami_id" {
  type        = string
  description = "(Optional) The unique identifier (ID) to the specific Amazon Machine Image for the auto scaling group to use when launching EC2 instances. If left empty (null), the latest version of Amazon Linux 2023 (AL2023) is used."
  default     = null
}

variable "ami_name_filter" {
  type        = list(string)
  description = "(Optional)"
  default     = ["al2023-ami-2023.*"]
}

variable "ami_owner" {
  type        = list(string)
  description = "(Optional) The AWS account ID associated with the AMI to be used for deploying the EC2 instance. The default account ID belongs to AWS itself."
  default     = ["137112412989"]
}

variable "aws_region" {
  type        = string
  description = "(Required) The name of the AWS data center to deploy resources to."
}

variable "aws_account_name" {
  type        = string
  description = "(Required) The name of the AWS account resources will operate in."
}

variable "function" {
  type        = string
  description = "(Optional) What function or purpose this resource serves."
  default     = "Bastion Host"
}

variable "hostname" {
  type        = string
  description = "(Required) A name for this bastion. It can only consist of lowercase alphanumeric characters and hyphens."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.hostname))
    error_message = "The hostname can only contain lowercase alphanumeric characters and hyphens."
  }
}

variable "iam_role_managed_policy_arns" {
  type        = list(string)
  description = "(Required) A list of IAM policy ARNs attach to the EC2 instance IAM Role."
}

variable "import_key_pair" {
  type        = bool
  description = "(Required) If the key pair you wish to use is already stored in AWS, then set this to 'False' and supply the key name in 'var.key_pair'."
}

variable "instance_type" {
  type        = string
  description = "(Required) The class of hardware to use for the EC2 instance."
}

variable "key_pair" {
  type        = map(string)
  description = ""

}

variable "load_balancer_listener_port" {
  type        = number
  description = "(Optional) The port number which the load balancer's listener process should check for connection requests."
  default     = 22
}

variable "load_balancer_listener_protocol" {
  type        = string
  description = "(Optional) Protocol for incoming connections from clients to the load balancer. For Application Load Balancers, valid values are 'HTTP' and 'HTTPS'. For Network Load Balancers, valid values are 'TCP', 'TCP_UDP', 'TLS', and 'UDP'."
  default     = "TCP"

  validation {
    condition = (
      contains(
        ["HTTP", "HTTPS", "TCP", "TCP_UDP", "TLS", "UDP"],
        var.load_balancer_listener_protocol
      )
    )
    error_message = "The allowed values are 'HTTP', 'HTTPS', 'TCP', 'TCP_UDP', 'TLS', and 'UDP'."
  }
}

variable "load_balancer_scheme" {
  type        = string
  description = "(Optional) Is this an internal load balancer or an internet-facing load balancer."
  default     = "internet-facing"

  validation {
    condition = (
      contains(["internal", "internet-facing"], var.load_balancer_scheme)
    )
    error_message = "The allowed values are 'internal' and 'internet-facing'."
  }
}

variable "load_balancer_type" {
  type        = string
  description = "(Optional) The type of load balancer to create. Valid options are 'application', 'network', and 'none'."
  default     = "network"

  validation {
    condition = (
      contains(["application", "network", "none"], var.load_balancer_type)
    )
    error_message = "The allowed values are 'application', 'network', and 'none'."
  }
}

variable "root_volume_iops" {
  type        = number
  description = "(Optional) The number of individual read and write operations that can be performed on the root EBS volume in one second."
  default     = 3000
}

variable "root_volume_size" {
  type        = number
  description = "(Optional) The desired size (in GiB) of the root EBS volume."
  default     = 8
}

variable "root_volume_type" {
  type        = string
  description = "(Optional) The volume type of the root EBS volume."
  default     = "gp3"

  validation {
    condition = contains(
      ["standard", "gp2", "gp3", "io1", "io2", "sc1", "st1"],
      var.root_volume_type
    )
    error_message = "The allowed values are 'standard', 'gp2', 'gp3', 'io1', 'io2', 'sc1', and 'st1'."
  }
}

variable "route53_zone_name" {
  type        = string
  description = "(Required) The name of the hosted zone where the bastion's DNS record is to be created."
}

variable "target_group_port" {
  type        = number
  description = "(Optional) The port number on which EC2 instances should receive incoming network traffic from the load balancer."
  default     = 22
}

variable "target_group_protocol" {
  type        = string
  description = "(Optional) Protocol to use when routing traffic to EC2 instances."
  default     = "TCP"

  validation {
    condition = (
      contains(
        ["GENEVE", "HTTP", "HTTPS", "TCP", "TCP_UDP", "TLS", "UDP"],
        var.target_group_protocol
      )
    )
    error_message = "The allowed values are 'GENEVE', 'HTTP', 'HTTPS', 'TCP', 'TCP_UDP', 'TLS', and 'UDP'."
  }
}

variable "user_volume_iops" {
  type        = number
  description = "(Optional) The number of individual read and write operations that can be performed on the user EBS volume in one second."
  default     = 3000
}

variable "user_volume_size" {
  type        = number
  description = "(Optional) The desired size (in GiB) of the user EBS volume."
  default     = 512
}

variable "user_volume_type" {
  type        = string
  description = "(Optional) The volume type of the user EBS volume."
  default     = "gp3"

  validation {
    condition = contains(
      ["standard", "gp2", "gp3", "io1", "io2", "sc1", "st1"],
      var.user_volume_type
    )
    error_message = "The allowed values are 'standard', 'gp2', 'gp3', 'io1', 'io2', 'sc1', and 'st1'."
  }
}

variable "vpc_name" {
  type        = string
  description = "(Required) The name of VPC to host this bastion and its resources."
}