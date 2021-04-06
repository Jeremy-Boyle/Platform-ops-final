terraform {
    required_version = ">= 0.13"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}
#Create a secure password
resource "random_password" "mongo_password" {
  	length           = 32
  	special          = true
  	override_special = "_%@"
}
resource "random_password" "postgres_password" {
  	length           = 32
  	special          = true
  	override_special = "_%@"
}

resource "random_password" "nagios_password" {
  	length           = 32
  	special          = true
  	override_special = "_%@"
}

#Set our region
locals {
  	region = "us-east-1"
	production_name = "dev"
	mongo_admin = "root"
	mongo_password = random_password.mongo_password.result
	postgres_admin = "root"
	postgres_password = random_password.postgres_password.result
	nagios_admin = "Log-Admin"
	nagios_password = random_password.nagios_password.result
}

#Get most recent AMI for ECS
data "aws_ami" "ecs" {
  	most_recent = true # get the latest version

  	filter {
    	name = "name"
    	values = ["amzn2-ami-ecs-*"] # ECS optimized image
  	}

  	filter {
    	name = "virtualization-type"
    	values = ["hvm"]
  	}

  	owners = ["amazon"] # Only official images
}

#Get most recent UBUNTU for nagios
data "aws_ami" "ubuntu" {
  	most_recent = true # get the latest version

  	filter {
    	name = "name"
    	values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  	}

  	filter {
    	name = "virtualization-type"
    	values = ["hvm"]
  	}

  	owners = ["099720109477"] # Only official images from ubuntu
}

# Configure the AWS creds and region
provider "aws" {
    region = local.region
	shared_credentials_file = "~/.aws/credentials"
  	profile                 = "TerraForm"
}

#Create our cluster
resource "aws_ecs_cluster" "cluster" {
  	name = "Website-Cluster-${local.production_name}"
}

#Create our repo for ecs images
resource "aws_ecr_repository" "repo" {
  	name                 = local.production_name
  	image_tag_mutability = "MUTABLE"

  	image_scanning_configuration {
    	scan_on_push = true
  	}
}

#Create our ssh keys
resource "tls_private_key" "key" {
  	algorithm = "RSA"
  	rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  	key_name   = local.production_name
  	public_key = tls_private_key.key.public_key_openssh
}

#Save our pem file
resource "local_file" "private_key" {
    content  = tls_private_key.key.private_key_pem
    filename = "keys/${local.production_name}.pem"
}

#Create our docker image local and upload it to our repo
resource null_resource "upload-image" {    
    depends_on = [
        aws_ecr_repository.repo
    ]

    provisioner "local-exec" { 
        command = "aws ecr get-login-password --region ${local.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.repo.repository_url}"
    }

	#Create our Nginx image
    provisioner "local-exec" { 
        command = "docker build -f conf/Nginx.dockerfile -t ${aws_ecr_repository.repo.repository_url}:website-v1 ."
    }

    provisioner "local-exec" { 
        command = "docker push ${aws_ecr_repository.repo.repository_url}:website-v1"
    }

	#Create our Mongo image
	provisioner "local-exec" { 
        command = "docker build -f conf/Mongo.dockerfile -t ${aws_ecr_repository.repo.repository_url}:mongo-v1 ."
    }

    provisioner "local-exec" { 
        command = "docker push ${aws_ecr_repository.repo.repository_url}:mongo-v1"
    }

	#Create our Postgres image
	provisioner "local-exec" { 
        command = "docker build -f conf/Postgres.dockerfile -t ${aws_ecr_repository.repo.repository_url}:postgres-v1 ."
    }

    provisioner "local-exec" { 
        command = "docker push ${aws_ecr_repository.repo.repository_url}:postgres-v1"
    }

	#Create our Nodejs image
	provisioner "local-exec" { 
        command = "docker build -f conf/Nodejs.dockerfile -t ${aws_ecr_repository.repo.repository_url}:nodejs-v1 ."
    }

    provisioner "local-exec" { 
        command = "docker push ${aws_ecr_repository.repo.repository_url}:nodejs-v1"
    }
}

#Create our log groups
resource "aws_cloudwatch_log_group" "log_group_nginx" {
  	name = "website-logs-${local.production_name}"
    tags = {
    	Environment = local.production_name
  	}
}

resource "aws_cloudwatch_log_group" "log_group_mongo" {
  	name = "mongo-logs-${local.production_name}"
    tags = {
    	Environment = local.production_name
  	}
}

resource "aws_cloudwatch_log_group" "log_group_postgres" {
  	name = "postgres-logs-${local.production_name}"
    tags = {
    	Environment = local.production_name
  	}
}

resource "aws_cloudwatch_log_group" "log_group_nodejs" {
  	name = "nodejs-logs-${local.production_name}"
    tags = {
    	Environment = local.production_name
  	}
}

#Print out configs
output "loadbalancer_dns" {
  	value       = aws_lb.loadbalancer.dns_name
  	description = "The address of the website loadbalancer"
}

output "database_dns" {
  	value       = aws_lb.internal_loadbalancer.dns_name
  	description = "The address of the internal loadbalancer for our databases"
}

output "mongo_username" {
  	value       = local.mongo_admin
  	description = "Username for the mongo database"
}

output "mongo_password" {
  	value       = local.mongo_password
  	description = "Password for the mongo database"
}

output "postgres_username" {
  	value       = local.postgres_admin
  	description = "Username for the postgres database"
}

output "postgres_password" {
  	value       = local.postgres_password
  	description = "Password for the postgres database"
}

output "nagios_username" {
  	value       = local.nagios_admin
  	description = "Username for the nagios database"
}

output "nagios_password" {
  	value       = local.nagios_password
  	description = "Password for the nagios database"
}

output "nagios_ip_address" {
  	value       = "${aws_instance.nagios-server.public_ip}:8080/nagios4/"
  	description = "Link to access the nagios server"
}
