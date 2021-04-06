# Create our dev VPC to launch our instances into
resource "aws_vpc" "vpc" {
  	cidr_block = "10.0.0.0/16"
	enable_dns_hostnames = true
	tags = {
    	Name = local.production_name
  	}
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "gate" {
  	vpc_id = aws_vpc.vpc.id
	tags = {
    	Name = local.production_name
  	}
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  	route_table_id         = aws_vpc.vpc.main_route_table_id
  	destination_cidr_block = "0.0.0.0/0"
  	gateway_id             = aws_internet_gateway.gate.id
}

# Create our subnets to launch our instances into
resource "aws_subnet" "sub-a" {
  	vpc_id                  = aws_vpc.vpc.id
  	cidr_block              = "10.0.0.0/24"
  	availability_zone       = "${local.region}a"
  	map_public_ip_on_launch = true
	tags = {
    	Name = "${local.production_name}-sub-a"
  	}
}

resource "aws_subnet" "sub-b" {
  	vpc_id                  = aws_vpc.vpc.id
  	cidr_block              = "10.0.1.0/24"
  	availability_zone       = "${local.region}b"
  	map_public_ip_on_launch = true
	tags = {
    	Name = "${local.production_name}-sub-b"
  	}
}

resource "aws_subnet" "sub-c" {
  	vpc_id                  = aws_vpc.vpc.id
  	cidr_block              = "10.0.2.0/24"
  	availability_zone       = "${local.region}c"
  	map_public_ip_on_launch = true
		tags = {
    	Name = "${local.production_name}-sub-c"
  	}
}
