# This data source retrieves information about the available Availability Zones
# within the specified AWS region (e.g us-west-2).
data "aws_availability_zones" "this" {
  state = "available"
}

# This data source retrieves information about a specific prefix list in AWS. A
# prefix list is a set of CIDR blocks that are used to simplify the setup of
# security groups and route tables. In this case, it is getting the prefix list
# associated with the Amazon S3 service.
data "aws_prefix_list" "this" {
  name = format("com.amazonaws.%s.s3", var.aws_region)
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = [format("%s-private*", var.vpc_name)]
  }
}
