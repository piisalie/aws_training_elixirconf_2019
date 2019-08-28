resource "aws_elb" "app_servers" {
  name = "elixir-in-the-jungle-${terraform.workspace}"

  subnets = ["${data.terraform_remote_state.vpc.outputs.public_subnet_id}"]
  security_groups = ["${aws_security_group.load_balancer.id}"]

  ###############################################################
  # If you have a domain and a SSL certificate you can reference
  # it here to allow for https traffic.
  ###############################################################
  # listener {
  #   instance_port= 443
  #   instance_protocol = "tcp"
  #   lb_port = 443
  #   lb_protocol = "ssl"
  #   ssl_certificate_id = "${aws_acm_certificate_validation.cert.certificate_arn}"
  # }

  listener {
    instance_port = 80
    instance_protocol = "tcp"
    lb_port = 80
    lb_protocol = "tcp"
  }

  ###############################################################
  # The Healthcheck below can be uncommented once a server
  # has been deployed on the app servers.  If they're  enabled
  # before, a server instance will never be healthy, and
  # never go into rotation.
  ###############################################################
  # health_check {
  #   healthy_threshold = 2
  #   unhealthy_threshold = 2
  #   timeout = 3
  #   target = "HTTP:4000/ping"
  #   interval = 5
  # }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:80"
    interval = 5
  }

  idle_timeout = 60
  connection_draining = true
  connection_draining_timeout = 60

  tags = {
    Name = "elixir-in-the-jungle-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_proxy_protocol_policy" "app_server" {
  load_balancer  = "${aws_elb.app_servers.name}"
  instance_ports = ["80", "443"]
}
