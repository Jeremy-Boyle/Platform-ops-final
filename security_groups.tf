#Create our secuirty groups to use
resource "aws_security_group" "loadbalancer" {
    name        = "allow_http_lb-${local.production_name}"
    description = "Allow http inbound traffic to ${local.production_name}"
    vpc_id      = aws_vpc.vpc.id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

#Create mongo security_groups
resource "aws_security_group" "mongo" {
    name        = "mongo-${local.production_name}"
    description = "Allow internal mongo inbound traffic to ${local.production_name}"
    vpc_id      = aws_vpc.vpc.id

    ingress {
        from_port   = 27017
        to_port     = 27017
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.101/32","10.0.1.101/32","10.0.2.101/32"]
        security_groups  = [aws_security_group.webservers.id]   
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

#Create postgres security_groups
resource "aws_security_group" "postgres" {
    name        = "postgres-${local.production_name}"
    description = "Allow internal postgres inbound traffic to ${local.production_name}"
    vpc_id      = aws_vpc.vpc.id

    ingress {
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.101/32","10.0.1.101/32","10.0.2.101/32"]
        security_groups  = [aws_security_group.webservers.id]   
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

#Create a security groups for our EC2 instances to talk to our loadbalancer
resource "aws_security_group" "webservers" {
    name        = "allow_http-${local.production_name}"
    description = "Allow http inbound traffic to our ${local.production_name} loadbalancer"
    vpc_id      = aws_vpc.vpc.id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        security_groups  = [aws_security_group.loadbalancer.id]   
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        security_groups  = [aws_security_group.loadbalancer.id]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

#Create a security groups for our nodejs instances to talk to our loadbalancer
resource "aws_security_group" "nodejs" {
    name        = "allow_nodejs-${local.production_name}"
    description = "Allow http inbound traffic to our ${local.production_name} loadbalancer"
    vpc_id      = aws_vpc.vpc.id

    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        security_groups  = [aws_security_group.loadbalancer.id]   
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}
#Create a security groups to connect to our EFS
resource "aws_security_group" "efs" {
    name        = "allow_nfs-${local.production_name}"
    description = "Allow nfs traffic to our ${local.production_name} EFS file system"
    vpc_id      = aws_vpc.vpc.id

    ingress {
        from_port   = 2049
        to_port     = 2049
        protocol    = "tcp"
        security_groups  = [aws_security_group.mongo.id,aws_security_group.postgres.id,aws_security_group.nodejs.id]
        
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}