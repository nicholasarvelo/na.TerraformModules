output "availability_zones" {
  value = data.aws_availability_zones.this.names
}

# This output resource produces a list of identifiers for all the private
# subnets retrieved by the 'aws_subnets.private' data source. This output
# resource facilitate the creation of extra VPC Service Endpoints within the
# root module.
output "private_subnets" {
  value = data.aws_subnets.private.ids
}

# This output resource facilitate the creation of extra VPC Service Endpoints
# within the root module.
output "vpc_id" {
  value = aws_vpc.this.id
}
