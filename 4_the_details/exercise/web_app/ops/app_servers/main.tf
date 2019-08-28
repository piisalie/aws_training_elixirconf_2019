provider "aws" {
  region = "${var.region}"
}

terraform {
  backend "s3" {
    bucket = "elixir-in-the-jungle-b"
    key = "app_servers_state"
    region = "us-east-2"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "elixir-in-the-jungle-b"
    key = "vpc_state"
    region = "us-east-2"
  }

  workspace = "${terraform.workspace}"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical according to Terraform docs
}
