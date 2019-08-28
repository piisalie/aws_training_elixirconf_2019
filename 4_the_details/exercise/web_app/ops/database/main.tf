provider "aws" {
  region = "${var.region}"
}

terraform {
  backend "s3" {
    bucket = "elixir-in-the-jungle-b"
    key = "database_state"
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

data "terraform_remote_state" "app_servers" {
  backend = "s3"
  config = {
    bucket = "elixir-in-the-jungle-b"
    key = "app_servers_state"
    region = "us-east-2"
  }

  workspace = "${terraform.workspace}"
}

