# VPC Module

----

This module automates the process of setting up network infrastructure on
AWS. It creates a new VPC and institutes private and public subnets as needed.
For each subnet, it builds a corresponding route table. It deploys an internet
gateway if there's at least one public subnet. For any private subnet, it sets
up an S3 endpoint. And if there's at least one private and one public subnet,
it creates a NAT gateway.

---

## Usage

The `vpc_cidr_block` variable.

An AWS Virtual Private Cloud (VPC) is a logically isolated virtual network
within an AWS account that mimics a traditional network operating in a data
center. It manages the available IP address range, subnets, internet and NAT
gateways, etc. These are all things that other AWS services operate on top of,
making it a fundamental service.

When creating an Amazon VPC, an IPv4 CIDR block for the VPC must be specified.
This CIDR block determines the total number of IP addresses that the VPC can
support; this is the VPC's address range.

The `subnet_cidr_blocks` variable

Subnets in a VPC are defined as either public or private. A subnet is public
if it has a route to an Internet Gateway (IGW). Resources (like EC2 instances)
in a public subnet can have a public IP address and communicate with the
internet. A subnet is private if it does not have a direct route to an IGW.
Resources in a private subnet cannot directly access the internet. However,
they can access the internet via a Network Address Translation (NAT) Gateway,
which allows outbound internet traffic while blocking inbound traffic
initiated from the internet.

Subnets are subdivisions of the VPC's address range. To create a subnet, you
specify an address range that is a subset of the VPC's CIDR block for that
subnet. You can create up to 4 public subnets and 4 private subnets. If you
don't need any subnets for public or private use, leave the respective list
empty '[]'.

In alignment with AWS best practices, creating at least two subnets of the
same type, be they private, public, or both, is advisable. Although this
module enables you to add more subnets later on, it doesn't support the
removal of subnets once they've been set up with this module.



## TL:DR
This module is a container of multiple AWS resources used collectively to provision a VPC, which can include:

1. **Up to Four Private Subnets:** 
    - Creation is based on the CIDR blocks you specify in `var.subnet_cidr_block`.
    - For each private subnet, a dedicated route table directs outbound traffic through a NAT gateway.
    - An S3 Endpoint is established, ensuring that these private subnets can securely access Amazon S3 without exiting the VPC.

2. **Up to Four Public Subnets:**
    - Their creation is also dependent on the CIDR blocks in `var.subnet_cidr_block`.
    - When these are set up, the system automatically generates an Internet Gateway. A corresponding route table then guides traffic through this gateway.

## Quick Start
Utilizing the default settings, you can quickly provision a VPC two private and two public subnets with the necessary route tables and an S3 VPC Endpoint with the following module block:

```terraform
module "vpc" {
  source = "$RELATIVE_PATH_TO/vpc"
}
```

### Examples
This module block creates a VPC with two private subnets, a NAT gateway and route tables (private subnets require their own route table), and an S3 Endpoint.
```terraform
module "vpc" {
  source = "../vpc"

  aws_region     = "us-east-1"
  vpc_name       = "myVPC"
  vpc_cidr_block = "202.101.0.0/16"
  subnet_cidr_blocks = {
    "private" = ["202.101.128.0/20", "202.101.144.0/20"]
    "public"  = []
  }
}
```
This module block creates a VPC with with four public subnets, and internet gateway and a single route table. 
```terraform
module "vpc" {
  source = "../vpc"

  aws_region     = "us-west-2"
  vpc_name       = "myVPC"
  vpc_cidr_block = "202.101.0.0/16"
  subnet_cidr_blocks = {
    "private" = []
    "public"  = ["202.101.0.0/20", "202.101.16.0/20", "202.101.32.0/20", "202.101.48.0/20"]
  }
}
```
This module block creates a VPC with two private subnets, a single public subnet, a NAT gateway and internet gateway, route tables, and an S3 Endpoint. We're also creating an additional VPC endpoint that enables traffic between 'myVPC' and 'someOtherVPC'.
```terraform
module "vpc" {
  source = "../vpc"

  aws_region     = "us-east-2"
  vpc_name       = "myVPC"
  vpc_cidr_block = "202.101.0.0/16"
  subnet_cidr_blocks = {
    "private" = ["202.101.128.0/20", "202.101.144.0/20"]
    "public"  = ["202.101.0.0/20"]
  }
}

resource "aws_vpc_endpoint" "someOtherVPC" {
  service_name      = "com.amazonaws.vpce.us-east-2.vpce-svc-1a234bc5de6t789fg"
  vpc_endpoint_type = "Interface"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnets
}
```

<!-- BEGIN_TF_DOCS -->
## Resources and Data Sources
Below is a table of AWS resources and data sources this Terraform module leverages to provision and manage specific infrastructure components. "Resources" are the primary components used to represent infrastructure objects provisioned and "data sources" fetch information on existing infrastructure components .

| Name | Type |
|------|------|
| [aws_default_route_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table) | resource |
| [aws_eip.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint_route_table_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association) | resource |
| [aws_availability_zones.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs
This is a list of supported variables that can be added to your module block. Only three are required to deploy a Fargate service as the rest have default values that apply to the majority of our services. If a Fargate service requires a value different from the default, add the variable name to your module block with the needed value.

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | (Optional) The name of the AWS data center to deploy resources to. | `string` | `"us-east-1"` | no |
| <a name="input_subnet_cidr_blocks"></a> [subnet\_cidr\_blocks](#input\_subnet\_cidr\_blocks) | (Optional) A map consisting of two lists, labeled 'private' and 'public'. Each of these lists contains a set of subnet CIDR blocks. Every subnet CIDR block must be a subset of the VPC's CIDR block. | `map(list(string))` | <pre>{<br>  "private": [<br>    "10.0.128.0/20",<br>    "10.0.144.0/20"<br>  ],<br>  "public": [<br>    "10.0.0.0/20",<br>    "10.0.16.0/20"<br>  ]<br>}</pre> | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | (Optional) The IPv4 CIDR block for the VPC. This CIDR block determines the total number of IP addresses that the VPC can support. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | (Optional) The name of the VPC. | `string` | `"main"` | no |

## Outputs
Outputs are used to display values of resources that have been created or modified in a Terraform configuration, and provide a way to share those values across modules and stacks, allowing users to see the results of their infrastructure deployment and to reference the outputs in other Terraform configurations, thus enabling modularity and reusability of Terraform code.

| Name | Description |
|------|-------------|
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | This output resource allows you to provision extra VPC Service Endpoints from the root module. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | This output resource allows you to provision extra VPC Service Endpoints from the root module. |
<!-- END_TF_DOCS -->