resource "aws_iam_instance_profile" "s3_app_access_profile" {
  name = "elixir-in-the-jungle_${terraform.workspace}_s3_app_access_profile"
  role = "${aws_iam_role.s3_app_access_role.name}"
}

resource "aws_iam_role" "s3_app_access_role" {
  name = "elixir-in-the-jungle_s3_app_access_role_${terraform.workspace}"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ec2.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF

  tags = {
    "Name" = "elixir-in-the-jungle"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_iam_policy" "app_access_policy" {
  name = "elixir-in-the-jungle_${terraform.workspace}_s3_app_access_policy"
  description = "Read and Write s3 policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": [
         "${data.terraform_remote_state.vpc.outputs.build_bucket_arn}/*",
         "arn:aws:s3:::aws-codedeploy-${var.region}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeAutoScalingGroups",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "s3_app_access" {
  name = "s3_app_access_policy_attachment_${terraform.workspace}"
  roles = ["${aws_iam_role.s3_app_access_role.name}"]
  policy_arn = "${aws_iam_policy.app_access_policy.arn}"
}

resource "aws_iam_role" "app_servers_codedeploy" {
  name = "elixir-in-the-jungle-${terraform.workspace}-codedeploy"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role = "${aws_iam_role.app_servers_codedeploy.name}"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "elixir-in-the-jungle-${terraform.workspace}-app_servers"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codepipeline_policy" {
  name = "codepipeline_policy-${terraform.workspace}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "${data.terraform_remote_state.vpc.outputs.build_bucket_arn}",
        "${data.terraform_remote_state.vpc.outputs.build_bucket_arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetApplication",
        "codedeploy:GetApplicationRevision",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "code_pipeline" {
  name = "code_pipeline_policy_attachment_${terraform.workspace}"
  roles = ["${aws_iam_role.codepipeline_role.name}"]
  policy_arn = "${aws_iam_policy.codepipeline_policy.arn}"
}
