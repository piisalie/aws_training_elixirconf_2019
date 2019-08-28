resource "aws_codedeploy_app" "app_servers" {
  name = "elixir-in-the-jungle-${terraform.workspace}"
}

resource "aws_sns_topic" "app_servers" {
  name = "elixir-in-the-jungle-${terraform.workspace}"
}

resource "aws_codedeploy_deployment_group" "app_servers" {
  app_name = "${aws_codedeploy_app.app_servers.name}"
  deployment_group_name = "elixir-in-the-jungle-${terraform.workspace}-app-servers"
  service_role_arn = "${aws_iam_role.app_servers_codedeploy.arn}"

  autoscaling_groups = "${aws_autoscaling_group.app_server.*.name}"

  load_balancer_info {
    elb_info {
      name = "${aws_elb.app_servers.name}"
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "CONTINUE_DEPLOYMENT"
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  trigger_configuration {
    trigger_events     = ["DeploymentStart", "DeploymentSuccess", "DeploymentFailure", "DeploymentStop", "DeploymentRollback", "InstanceStart", "InstanceSuccess", "InstanceFailure"]
    trigger_name       = "code-deploy"
    trigger_target_arn = "${aws_sns_topic.app_servers.arn}"
  }

  lifecycle {
    ignore_changes = [ "autoscaling_groups" ]
  }
}
