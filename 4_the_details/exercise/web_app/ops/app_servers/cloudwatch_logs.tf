variable "log_retention" {
  default = {
    example = 3
  }
}

resource "aws_cloudwatch_log_group" "app_servers" {
  name = "elixir-in-the-jungle-${terraform.workspace}-app-servers"

  retention_in_days = "${lookup(var.log_retention, terraform.workspace)}"

  tags = {
    Environment = "${terraform.workspace}"
    Application = "elixir-in-the-jungle"
  }
}
