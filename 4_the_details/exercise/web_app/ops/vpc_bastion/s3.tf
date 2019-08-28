resource "aws_s3_bucket" "build_bucket" {
  bucket_prefix = "elixir-in-the-jungle-${terraform.workspace}-builds"
  acl = "private"

  tags = {
    Name = "elixir-in-the-jungle"
    Environment = "${terraform.workspace}"
  }

  versioning {
    enabled = true
  }

 lifecycle_rule {
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_public_access_block" "build_bucket" {
  bucket = "${aws_s3_bucket.build_bucket.id}"

  ignore_public_acls = true
  restrict_public_buckets = true
  block_public_acls = true
  block_public_policy = true
}
