data "template_file" "cloud_init" {
  template = "${file("cloud_init.tpl")}"

  vars = {
    bucket_name = "aws-codedeploy-${var.region}"
    build_bucket = "${data.terraform_remote_state.vpc.outputs.build_bucket_name}"
    environment = "${terraform.workspace}"
    region = "${var.region}"
    vpc_cidr_block = "${data.terraform_remote_state.vpc.outputs.vpc_cidr_block}"
 }
}

resource "aws_launch_configuration" "app_server" {
  name = "elixir-in-the-jungle-${terraform.workspace}-app-servers"

  iam_instance_profile = "${aws_iam_instance_profile.s3_app_access_profile.name}"

  instance_type = "${lookup(var.instance_size, terraform.workspace)}"
  image_id = "${data.aws_ami.ubuntu.id}"

  security_groups = ["${aws_security_group.app_servers.id}"]

  user_data = "${data.template_file.cloud_init.rendered}"
}

resource "aws_autoscaling_group" "app_server" {
  count = "${var.initial_asg ? 1 : 0}"
  name_prefix = "elixir-in-the-jungle-${terraform.workspace}-app-servers"

  desired_capacity = 1
  max_size = 2
  min_size = 1

  vpc_zone_identifier = ["${data.terraform_remote_state.vpc.outputs.private_subnet_id}"]

  load_balancers = ["${aws_elb.app_servers.name}"]
  health_check_type = "ELB"
  launch_configuration = "${aws_launch_configuration.app_server.name}"

  tags = [
    {
      key = "Name"
      value = "elixir-in-the-jungle"
      propagate_at_launch = true
    },
    {
      key = "Environment"
      value = "${terraform.workspace}"
      propagate_at_launch = true
    }
  ]
}
