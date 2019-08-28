resource "aws_iam_instance_profile" "bastion_profile" {
  name = "elixir-in-the-jungle-${terraform.workspace}_bastion"
  role = "${aws_iam_role.bastion.name}"
}

resource "aws_iam_policy" "bastion" {
  name = "elixir-in-the-jungle-${terraform.workspace}_bastion"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": [
         "${aws_s3_bucket.build_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeAutoScalingGroups",
        "ec2:DescribeInstances",
        "codedeploy:Batch*",
        "codedeploy:Get*",
        "codedeploy:List*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "bastion" {
  name = "elixir-in-the-jungle-${terraform.workspace}_bastion"

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
    Name = "elixir-in-the-jungle"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_iam_policy_attachment" "bastion" {
  name = "elixir-in-the-jungle-${terraform.workspace}-bastion"
  roles = ["${aws_iam_role.bastion.name}"]
  policy_arn = "${aws_iam_policy.bastion.arn}"
}
