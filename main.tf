# S3 buckets
resource "aws_s3_bucket" "s3-test" {
  bucket = "epm-nikitsenka-test"
  tags = {
    Name = "epm-nikitsenka-test"
  }
}

# Trust policy local
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Remote
data "aws_iam_policy_document" "assume_remote_role" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::880522701894:role/andrei_test_role_s3_read"]
  }
}