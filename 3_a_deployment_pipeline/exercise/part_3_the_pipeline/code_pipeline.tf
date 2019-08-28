resource "aws_codepipeline" "app_servers" {
  name = "elixir-in-the-jungle-${terraform.workspace}"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = "${data.terraform_remote_state.vpc.outputs.build_bucket_name}"
    type = "S3"
  }

  stage {
    name = "Source"

    action {
      name = "App-Change"
      category = "Source"
      owner = "AWS"
      provider = "S3"
      version = "1"
      output_artifacts = ["release"]

      configuration = {
        S3Bucket = "${data.terraform_remote_state.vpc.outputs.build_bucket_name}"
        S3ObjectKey = "latest.tar.gz"
        PollForSourceChanges = "true"
      }
    }

    action {
      name = "Config-Change"
      category = "Source"
      owner = "AWS"
      provider = "S3"
      version = "1"
      output_artifacts = ["env"]

      configuration = {
        S3Bucket = "${data.terraform_remote_state.vpc.outputs.build_bucket_name}"
        S3ObjectKey = "env"
        PollForSourceChanges = "true"
      }
    }

  }

  stage {
    name = "Deploy"

    action {
      name = "Deploy"
      category = "Deploy"
      owner = "AWS"
      provider = "CodeDeploy"
      input_artifacts = ["release"]
      version = "1"

      configuration = {
        ApplicationName = "${aws_codedeploy_app.app_servers.name}"
        DeploymentGroupName = "${aws_codedeploy_deployment_group.app_servers.deployment_group_name}"
      }
    }
  }
}
