provider "aws" {
  region = "${var.region}"
}

terraform {
  backend "s3" {
    bucket = "elixir-in-the-jungle-b"
    key = "vpc_state"
    region = "us-east-2"
  }
}
