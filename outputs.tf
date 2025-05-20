# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# output "instance_ami" {
#   value = aws_instance.ubuntu.ami
# }

# output "instance_arn" {
#   value = aws_instance.ubuntu.arn
# }
output "vpc_id" {
  description = "ID of project VPC"
  value       = volcengine_vpc.foo.account_id
}

output "subnet_name" {
  description = "subnets"
  value = volcengine_subnet.pria.subnet_name
}

output "subnet_id" {
  description = "subnets"
  value = volcengine_subnet.pria.id
}