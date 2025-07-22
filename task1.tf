resource "aws_iam_role" "lambda_list_my_buckets_role" {
  name               = "lambda_list_my_buckets_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "s3_list_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "s3_list_policy" {
  name   = "lambda_s3_list_policy"
  policy = data.aws_iam_policy_document.s3_list_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "s3_list" {
  role       = aws_iam_role.lambda_list_my_buckets_role.name
  policy_arn = aws_iam_policy.s3_list_policy.arn
}

data "archive_file" "lambda_list_my_buckets" {
  type        = "zip"
  source_file = "${path.module}/lambdas/list_my_buckets/src/lambda.py"
  output_path = "lambda_list_my_buckets.zip"
}

resource "aws_lambda_function" "lambda_list_my_buckets" {
  filename         = "lambda_list_my_buckets.zip"
  function_name    = "python_tf_task1"
  role             = aws_iam_role.lambda_list_my_buckets_role.arn
  source_code_hash = data.archive_file.lambda_list_my_buckets.output_base64sha512
  architectures    = ["arm64"]
  runtime          = "python3.12"
  handler          = "lambda.lambda_handler"
}