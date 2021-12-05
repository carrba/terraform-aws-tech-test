provider "aws" {
  region = var.region
}

resource "aws_dynamodb_table" "dynamodb-table" {
  name         = "bc-ec2-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  range_key    = "CreationTime"


  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "CreationTime"
    type = "N"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name    = "bc-ec2-state"
    Owner   = var.owner
    Project = var.project
  }
}

