output "private_subnet_id" { value = "${aws_subnet.private.id}" }
output "public_subnet_id" { value = "${aws_subnet.public.id}" }
output "vpc_cidr_block" { value = "${aws_vpc.elixir-in-the-jungle.cidr_block}" }
output "vpc_id" { value = "${aws_vpc.elixir-in-the-jungle.id}" }
output "bastion_security_group_id" { value = "${aws_security_group.bastion.id}" }
output "build_bucket_arn" { value = "${aws_s3_bucket.build_bucket.arn}" }
output "build_bucket_name" { value = "${aws_s3_bucket.build_bucket.id}" }
output "bastion_ip" { value = "${aws_instance.bastion.public_ip}"}
