resource "aws_iam_role" "lambda_read_from_my_bucket_role" {
  name               = "lambda_read_from_my_bucket_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "s3_read_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::nikitsenka-readonly-storage/response.json"]
  }
}

resource "aws_iam_policy" "s3_read_policy" {
  name   = "lambda_s3_read_policy"
  policy = data.aws_iam_policy_document.s3_read_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "s3_read_file" {
  role       = aws_iam_role.lambda_read_from_my_bucket_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

data "archive_file" "lambda_read_from_my_bucket" {
  type        = "zip"
  source_file = "${path.module}/lambdas/read_from_my_bucket/src/lambda.py"
  output_path = "lambda_read_from_my_bucket.zip"
}

resource "aws_lambda_function" "lambda_read_from_my_bucket" {
  filename         = "lambda_read_from_my_bucket.zip"
  function_name    = "python_tf_task2_1"
  role             = aws_iam_role.lambda_read_from_my_bucket_role.arn
  source_code_hash = data.archive_file.lambda_read_from_my_bucket.output_base64sha512
  architectures    = ["arm64"]
  runtime          = "python3.12"
  handler          = "lambda.lambda_handler"
}