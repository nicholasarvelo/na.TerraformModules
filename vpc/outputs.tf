# This output resource allows you to provision extra VPC Service Endpoints from
# the root module.
output "private_subnets" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

# This output resource allows you to provision extra VPC Service Endpoints from
# the root module.
output "vpc_id" {
  value = aws_vpc.this.id
}
