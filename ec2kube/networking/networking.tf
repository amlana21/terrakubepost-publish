terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket = "<bucket_name>"
    key    = "<state_key>"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}


resource "aws_vpc" "kubevpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "kubevpc"
  }
}

resource "aws_internet_gateway" "kube_gw" {
  vpc_id = resource.aws_vpc.kubevpc.id

  tags = {
    Name = "kube_gw"
  }

}

resource "aws_network_acl" "kube_public_nacl" {
  vpc_id = resource.aws_vpc.kubevpc.id

  subnet_ids =[resource.aws_subnet.kube_subnet.id]

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "-1"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 310
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 6443
    to_port    = 6443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "kube_nacl"
  }

  
}

resource "aws_security_group" "kube_sg" {
  name        = "kube_sg"
  description = "sg for kube"
  vpc_id      = resource.aws_vpc.kubevpc.id

  ingress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 6443
    to_port    = 6443
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "kube_sg"
  }
}

resource "aws_route_table" "kube_rt" {
  vpc_id = resource.aws_vpc.kubevpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = resource.aws_internet_gateway.kube_gw.id
  }

  tags = {
    Name = "kube_rt"
  }
}

resource "aws_subnet" "kube_subnet" {
  vpc_id     = resource.aws_vpc.kubevpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "kube_subnet"
  }
}

resource "aws_subnet" "kube_subnet_2" {
  vpc_id     = resource.aws_vpc.kubevpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "kube_subnet_2"
  }
}

resource "aws_route_table_association" "kube_subnet_assoc" {
  subnet_id      = resource.aws_subnet.kube_subnet.id
  route_table_id = resource.aws_route_table.kube_rt.id
}

resource "aws_route_table_association" "kube_subnet_assoc_2" {
  subnet_id      = resource.aws_subnet.kube_subnet_2.id
  route_table_id = resource.aws_route_table.kube_rt.id
}

resource "aws_network_interface" "kube_instance_eni" {
  subnet_id       = resource.aws_subnet.kube_subnet.id
  security_groups = [resource.aws_security_group.kube_sg.id]

  
}
