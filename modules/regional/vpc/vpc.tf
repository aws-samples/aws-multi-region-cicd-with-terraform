module "vpc" {
  source  = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v3.7.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = var.vpc_enable_nat_gateway
  single_nat_gateway = var.vpc_single_nat_gateway
  enable_dns_hostnames = var.vpc_enable_dns_hostnames
  public_subnet_tags = var.vpc_public_subnet_tags
  private_subnet_tags = var.vpc_private_subnet_tags
  tags               = var.vpc_tags
  create_igw         = var.vpc_create_igw
}

resource "aws_security_group" "vpc_tls" {
  name_prefix = "${var.vpc_name}-vpc_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = var.vpc_tags
}

