resource "aws_db_subnet_group" "app_server" {
  name       = "elixir-in-the-jungle-${terraform.workspace}"
  subnet_ids = [
    "${data.terraform_remote_state.vpc.outputs.private_subnet_id}",
    "${data.terraform_remote_state.vpc.outputs.private_subnet_id_b}"
  ]
}

resource "aws_db_instance" "app_server" {
  allocated_storage = "${lookup(var.instance_storage, terraform.workspace)}"
  storage_type = "gp2"
  engine = "postgres"
  engine_version = "11.4"
  instance_class = "${lookup(var.instance_size, terraform.workspace)}"
  name = "eitj${terraform.workspace}"
  username = "${var.db_user}"
  password = "${var.db_pw}"
  vpc_security_group_ids = ["${aws_security_group.rds.id}"]
  availability_zone = "${var.region}a"
  multi_az = false
  db_subnet_group_name = "${aws_db_subnet_group.app_server.name}"
  identifier = "elixir-in-the-jungle${terraform.workspace}"
  final_snapshot_identifier = "elixir-in-the-jungle-${terraform.workspace}-final-snapshot"
  backup_retention_period = "${lookup(var.backup_retention, terraform.workspace)}"
}
