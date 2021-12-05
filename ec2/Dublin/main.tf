provider "aws" {
  region = var.region
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc-cidr
  enable_dns_hostnames = true
  tags = {
    Owner   = var.owner
    Project = var.project
  }
}

resource "aws_subnet" "public-subnets" {
  count             = var.az_number
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnets[count.index]
  availability_zone = "${var.region}${var.az[count.index]}"
  tags = {
    Name    = "subnet-${count.index + 1}"
    Owner   = var.owner
    Project = var.project
  }
}

resource "aws_route_table" "public-subnet-route-table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Owner   = var.owner
    Project = var.project
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Owner   = var.owner
    Project = var.project
  }
}

resource "aws_route" "public-subnet-route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.public-subnet-route-table.id
}

resource "aws_route_table_association" "public-subnet-route-table-associations" {
  count          = var.az_number
  subnet_id      = aws_subnet.public-subnets[count.index].id
  route_table_id = aws_route_table.public-subnet-route-table.id
}

resource "aws_key_pair" "web" {
  public_key = file(pathexpand(var.public_key))
}

resource "aws_instance" "web-instance" {
  count                       = var.az_number
  ami                         = "ami-cdbfa4ab"
  instance_type               = "t2.small"
  vpc_security_group_ids      = [aws_security_group.web-instance-security-group.id]
  subnet_id                   = aws_subnet.public-subnets[count.index].id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.web.key_name
  user_data                   = <<EOF
#!/bin/sh
yum install -y nginx
service nginx start
EOF
  tags = {
    Name    = "BC${count.index + 1}"
    Owner   = var.owner
    Project = var.project
  }
}

resource "aws_security_group" "web-instance-security-group" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Owner   = var.owner
    Project = var.project
  }
}