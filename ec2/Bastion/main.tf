provider "aws" {
  region = var.region
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc-cidr
  enable_dns_hostnames = true
  tags = {
    Name    = "BC-vpc"
    Owner   = var.owner
    Project = var.project
  }
}

# Public Subnet
resource "aws_subnet" "public-subnet" {
  count                   = var.az_number
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnets[count.index]
  availability_zone       = "${var.region}${var.az[count.index]}"
  map_public_ip_on_launch = true
  tags = {
    Name    = "subnet-public-${var.az[count.index]}"
    Owner   = var.owner
    Project = var.project
  }
}

resource "aws_route_table" "public-subnet-route-table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name    = "BC-public-route-table"
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

resource "aws_eip" "nat_eip" {
  count = var.az_number
  vpc   = true
  tags = {
    Name    = "eip-${var.az[count.index]}"
    Owner   = var.owner
    Project = var.project
  }
}

resource "aws_nat_gateway" "ngw" {
  count         = var.az_number
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public-subnet[count.index].id

  tags = {
    Name    = "ngw-${var.az[count.index]}"
    Owner   = var.owner
    Project = var.project
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route" "public-subnet-route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.public-subnet-route-table.id
}

resource "aws_route_table_association" "public-subnet-route-table-associations" {
  count          = var.az_number
  subnet_id      = aws_subnet.public-subnet[count.index].id
  route_table_id = aws_route_table.public-subnet-route-table.id
}

# Private subnets
resource "aws_subnet" "private-subnets" {
  count             = var.az_number
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet-public[count.index]
  availability_zone = "${var.region}${var.az[count.index]}"
  tags = {
    Name    = "subnet-${var.az[count.index]}"
    Owner   = var.owner
    Project = var.project
  }
}

resource "aws_route_table" "private-subnet-route-table" {
  count  = var.az_number
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name    = "BC-private-route-table-${var.az[count.index]}"
    Owner   = var.owner
    Project = var.project
  }
}

resource "aws_route" "private-subnet-route" {
  count                  = var.az_number
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw[count.index].id
  route_table_id         = aws_route_table.private-subnet-route-table[count.index].id
}

resource "aws_route_table_association" "private-subnet-route-table-associations" {
  count          = var.az_number
  subnet_id      = aws_subnet.private-subnets[count.index].id
  route_table_id = aws_route_table.private-subnet-route-table[count.index].id
}

# EC2 instances
resource "aws_key_pair" "web" {
  public_key = file(pathexpand(var.public_key))
}

resource "aws_instance" "web-instance" {
  count                       = var.az_number
  ami                         = "ami-cdbfa4ab"
  instance_type               = "t2.small"
  vpc_security_group_ids      = [aws_security_group.web-instance-security-group.id]
  subnet_id                   = aws_subnet.private-subnets[count.index].id
  associate_public_ip_address = false
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

# Bastion Host
resource "aws_instance" "bastion-instance" {
  ami                         = "ami-cdbfa4ab"
  instance_type               = "t2.small"
  vpc_security_group_ids      = [aws_security_group.bastion-security-group.id]
  subnet_id                   = aws_subnet.public-subnet[0].id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.web.key_name

  tags = {
    Name    = "BC-bastion"
    Owner   = var.owner
    Project = var.project
  }
}

resource "aws_security_group" "bastion-security-group" {
  vpc_id = aws_vpc.vpc.id

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