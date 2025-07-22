resource "aws_iam_role" "lambda_read_from_my_bucket_s3_pol_role" {
  name               = "lambda_read_from_my_bucket_s3_pol_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.lambda_read_from_my_bucket_s3_pol_role.arn]
    }
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::nikitsenka-readonly-storage-policy/response.json"]
  }
}

data "aws_s3_bucket" "nikitsenka-readonly-storage-policy" {
  bucket = "nikitsenka-readonly-storage-policy"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = data.aws_s3_bucket.nikitsenka-readonly-storage-policy.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}

data "archive_file" "lambda_read_from_my_bucket_s3_policy" {
  type        = "zip"
  source_file = "${path.module}/lambdas/read_from_my_bucket_s3_policy/src/lambda.py"
  output_path = "lambda_read_from_my_bucket_s3_policy.zip"
}

resource "aws_lambda_function" "lambda_read_from_my_bucket_s3_policy" {
  filename         = "lambda_read_from_my_bucket_s3_policy.zip"
  function_name    = "python_tf_task2_2"
  role             = aws_iam_role.lambda_read_from_my_bucket_s3_pol_role.arn
  source_code_hash = data.archive_file.lambda_read_from_my_bucket_s3_policy.output_base64sha512
  architectures    = ["arm64"]
  runtime          = "python3.12"
  handler          = "lambda.lambda_handler"
}