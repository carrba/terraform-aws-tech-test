provider "aws" {
  region = var.region
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc-cidr
  enable_dns_hostnames = true
  tags = {
      Owner = var.owner
      Project = var.project
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet-cidr-public
  availability_zone = "${var.region}a"
    tags = {
      Owner = var.owner
      Project = var.project
  }
}