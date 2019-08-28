resource "aws_instance" "bastion" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type  = "${var.instance_size}"
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
  subnet_id = "${aws_subnet.public.id}"
  iam_instance_profile = "${aws_iam_instance_profile.bastion_profile.name}"
  associate_public_ip_address = true
  user_data = "${data.template_cloudinit_config.bastion.rendered}"

  tags = {
    Name = "elixir-in-the-jungle"
    Environment = "${terraform.workspace}"
  }
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

data "template_file" "cloud_init" {
  template = "${file("cloud_init.tpl")}"

  vars = {
    bucket_name = "${aws_s3_bucket.build_bucket.id}"
    slack_webhook = "https://example.com"
    region = "${var.region}"
    codedeploy_app_name = "elixir-in-the-jungle-${terraform.workspace}"
  }
}

data "template_cloudinit_config" "bastion" {
  gzip = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = "${data.template_file.cloud_init.rendered}"
  }
}
