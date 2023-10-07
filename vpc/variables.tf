variable "aws_region" {
  type        = string
  description = "(Optional) The name of the AWS data center to deploy resources to."
  default     = "us-east-1"
}


variable "subnet_cidr_blocks" {
  type        = map(list(string))
  description = "(Optional) A map consisting of two lists, labeled 'private' and 'public'. Each of these lists contains a set of subnet CIDR blocks. Every subnet CIDR block must be a subset of the VPC's CIDR block."
  default = {
    "private" = ["10.0.128.0/20", "10.0.144.0/20"]
    "public"  = ["10.0.0.0/20", "10.0.16.0/20"]
  }

  validation {
    condition = (
      length(var.subnet_cidr_blocks["private"]) <= 4 &&
      length(var.subnet_cidr_blocks["public"]) <= 4
    )
    error_message = "You can create up to 4 public subnets and 4 private subnets."
  }
}

variable "vpc_cidr_block" {
  type        = string
  description = "(Optional) The IPv4 CIDR block for the VPC. This CIDR block determines the total number of IP addresses that the VPC can support."
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  type        = string
  description = "(Optional) The name of the VPC."
  default     = "main"
}
