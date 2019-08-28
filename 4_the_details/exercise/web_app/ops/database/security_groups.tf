resource "aws_security_group" "rds" {
  name = "elixir-in-the-jungle-${terraform.workspace}-rds"
  vpc_id = "${data.terraform_remote_state.vpc.outputs.vpc_id}"

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [
      "${data.terraform_remote_state.app_servers.outputs.security_group_id}"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
