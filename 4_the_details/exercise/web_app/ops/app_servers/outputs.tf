output "load_balancer_dns" { value = "${aws_elb.app_servers.dns_name}"}
output "security_group_id" { value = "${aws_security_group.app_servers.id}"}
