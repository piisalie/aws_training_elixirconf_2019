variable "vpc_cidr_blocks" {
  default = {
    example = "10.20.0.0/16"
  }
}

variable "region" {}

variable "instance_size" { default = "t2.micro" }
