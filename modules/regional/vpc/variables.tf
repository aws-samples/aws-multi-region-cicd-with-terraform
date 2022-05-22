variable vpc_name {
  description = "Name of VPC"
  type        = string
}

variable vpc_cidr {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable vpc_azs {
  description = "Availability zones for VPC"
  type        = list(string)
}

variable vpc_private_subnets {
  description = "Private subnets for VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable vpc_public_subnets {
  description = "Public subnets for VPC"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable vpc_single_nat_gateway {
  description = "Set to true to provision a single shared NAT Gateway across all of private networks"
  default = true
}

variable vpc_enable_nat_gateway {
  description = "Enable NAT gateway for VPC"
  type        = bool
  default     = false
}

variable vpc_enable_dns_hostnames {
  description = "Enable DNS hostnames for VPC"
  type        = bool
  default     = true
}

variable vpc_create_igw {
  description = "Create internet gateway for VPC"
  type        = bool
  default     = true
}

variable vpc_tags {
  description = "Tags to apply to resources created by VPC module"
  type        = map(string)
}

variable "vpc_public_subnet_tags" {
  description = "Additional tags for the public subnets"
  type        = map(string)
  default     = {}
}

variable "vpc_private_subnet_tags" {
  description = "Additional tags for the private subnets"
  type        = map(string)
  default     = {}
}

// Ref: https://learn.hashicorp.com/tutorials/terraform/module-use and https://learn.hashicorp.com/tutorials/terraform/eks