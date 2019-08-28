resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "with_sns" {
    statement_id = "AllowExecutionFromSNS"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.slack_lambda.arn}"
    principal = "sns.amazonaws.com"
    source_arn = "${aws_sns_topic.app_servers.arn}"
}

resource "aws_sns_topic_subscription" "code_deploy_updates" {
  topic_arn = "${aws_sns_topic.app_servers.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.slack_lambda.arn}"
}

resource "aws_lambda_function" "slack_lambda" {
  filename      = "sns_to_slack.zip"
  function_name = "sns_to_slack"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "index.handler"

  source_code_hash = "${filebase64sha256("sns_to_slack.zip")}"

  runtime = "nodejs10.x"

  environment {
    variables = {
      webhook = "/services/TEW1PRACD/BMSERDBLN/LPPzNlwdQZ0H8CtxlacQbZYw"
    }
  }
}
