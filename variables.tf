variable "volc_region" {
  description = "volc region"
  type = string
  default = "cn-guangzhou"
}

variable "vpc_name" {
  type = string
  default = "ykx-common-vpc"
}

variable "vpc_cidr_block" {
  description = "value"
  type = string
  default = "172.16.0.0/16"
}