resource "aws_s3_bucket_object" "object" {
  bucket = "${data.terraform_remote_state.vpc.outputs.build_bucket_name}"
  key = "env"
  source = "./.env.${terraform.workspace}"

  etag = "${md5(file("./.env.${terraform.workspace}"))}"
}
