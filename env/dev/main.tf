# Archivo: env/dev/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Asegúrate de que esta sea tu región
}


data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"] # Propietario de Amazon

  filter {
    name   = "name"
    # Patrón de nombre para AL2023 (buscará la imagen base más reciente)
    values = ["al2023-ami-2023.*-kernel-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


module "vpc" {
  source      = "../../modules/vpc"
  environment = var.environment
}


module "security_groups" {
  source      = "../../modules/security_groups"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id # Pasa la salida de VPC como entrada
}


module "ec2_asg" {
  source              = "../../modules/ec2_asg"
  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids # Pasa las subredes de VPC
  alb_sg_id           = module.security_groups.alb_sg_id # Pasa el SG de ALB
  app_sg_id           = module.security_groups.app_sg_id # Pasa el SG de App

  # Variables específicas de dev

  # LA AMI SE OBTIENE DEL DATA SOURCE, NO DE var.ami_id
  ami_id           = data.aws_ami.amazon_linux_2023.id 

  instance_type    = var.instance_type
  key_name         = var.key_name
  min_instances    = var.min_instances
  max_instances    = var.max_instances
  desired_capacity = var.desired_capacity
}

output "dev_alb_dns_name" {
  value = module.ec2_asg.alb_dns_name
}