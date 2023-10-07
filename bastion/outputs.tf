# In Terraform, an output is used to export data about created resources so that
# you can access that data elsewhere.

# Exports the ID of the Bastion's security group so that we can create
# additional ingress rules for this security group from the root module.
output "bastion_security_group_id" {
  value = aws_security_group.this.id
}

output "bastion_urls" {
  value = [for record in aws_route53_record.this : record.fqdn]
}

output "bastion_instance_id" {
  value = aws_instance.this.id
}