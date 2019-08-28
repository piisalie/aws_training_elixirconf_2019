resource "aws_security_group" "app_servers" {
  name = "app_servers"
  vpc_id = "${data.terraform_remote_state.vpc.outputs.vpc_id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [
      "${data.terraform_remote_state.vpc.outputs.bastion_security_group_id}"
    ]
  }

  ingress {
    from_port = 4369
    to_port = 4369
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = 9100
    to_port = 9155
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.load_balancer.id}"
    ]
  }

  # ingress {
  #   from_port = 443
  #   to_port = 443
  #   protocol = "tcp"
  #   security_groups = [
  #     "${aws_security_group.load_balancer.id}"
  #   ]
  # }

  ingress {
    from_port = 4000
    to_port = 4000
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.load_balancer.id}"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "load_balancer" {
  name = "elixir-in-the-jungle-${terraform.workspace}"

  vpc_id = "${data.terraform_remote_state.vpc.outputs.vpc_id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   from_port = 443
  #   to_port = 443
  #   protocol = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # egress {
  #   from_port = 443
  #   to_port = 443
  #   protocol = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port = 4000
    to_port = 4000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
