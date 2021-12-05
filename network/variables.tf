variable "region" {
}

variable "vpc-cidr" {
}

variable "subnet-cidr-public" {
}

# for the purpose of this exercise use the default key pair on your local system
variable "public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "owner" {
  type = string
  default = "Brian Carr"
}

variable "project" {
  type = string
  default = "Tech Test"
}
