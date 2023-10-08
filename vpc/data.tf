# This data source retrieves information about the available Availability Zones
# within the specified AWS region. We only want to work with zones in an
# 'available' state.
data "aws_availability_zones" "this" {
  state = "available"
}
