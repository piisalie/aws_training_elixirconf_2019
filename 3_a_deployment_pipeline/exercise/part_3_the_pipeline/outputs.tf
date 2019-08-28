output "load_balancer_dns" { value = "${aws_elb.app_servers.dns_name}"}
