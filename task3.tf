resource "aws_iam_role" "lambda_list_remote_buckets_role" {
  name               = "lambda_list_remote_buckets_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "assume_remote_role" {
  name   = "assume_remote_role"
  policy = data.aws_iam_policy_document.assume_remote_role.json
}

resource "aws_iam_role_policy_attachment" "attach_assume_policy" {
  role       = aws_iam_role.lambda_list_remote_buckets_role.name
  policy_arn = aws_iam_policy.assume_remote_role.arn
}

data "archive_file" "lambda_list_remote_buckets" {
  type        = "zip"
  source_file = "${path.module}/lambdas/list_remote_buckets/src/lambda.py"
  output_path = "lambda_list_remote_buckets.zip"
}

resource "aws_lambda_function" "lambda_list_remote_buckets" {
  filename         = "lambda_list_remote_buckets.zip"
  function_name    = "python_tf_task3"
  role             = aws_iam_role.lambda_list_remote_buckets_role.arn
  source_code_hash = data.archive_file.lambda_list_remote_buckets.output_base64sha512
  architectures    = ["arm64"]
  runtime          = "python3.12"
  handler          = "lambda.lambda_handler"
}