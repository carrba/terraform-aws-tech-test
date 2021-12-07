variable "region" {
}

variable "vpc-cidr" {
}

# for the purpose of this exercise use the default key pair on your local system
variable "public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "owner" {
  type    = string
  default = "Brian Carr"
}

variable "project" {
  type    = string
  default = "Tech Test"
}

variable "subnets" {
  type = list(string)
}

variable "subnet-public" {
  type        = list(string)
  description = "Public subnet for bastion host"
}

variable "az_number" {
  type = number
}

variable "az" {
  type    = list(string)
  default = ["a", "b", "c", "d", "e", "f"]
}