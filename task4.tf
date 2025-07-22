# Setup SNS
resource "aws_sns_topic" "email_from_lambda" {
  name = "email_from_lambda"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.email_from_lambda.arn
  protocol  = "email"
  endpoint  = "andrei_nikitsenka@epam.com"
}

# IAM SNS
resource "aws_iam_role" "lambda_publish_sns_role" {
  name               = "lambda_publish_sns_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "allow_publish_sns_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.email_from_lambda.arn]
  }
}

resource "aws_iam_policy" "allow_publish_sns_policy" {
  name   = "publish-sns-policy"
  policy = data.aws_iam_policy_document.allow_publish_sns_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_publish_sns_policy" {
  role       = aws_iam_role.lambda_publish_sns_role.name
  policy_arn = aws_iam_policy.allow_publish_sns_policy.arn
}

# IAM S3
data "aws_iam_policy_document" "s3_list_policy_doc_task4" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "s3_list_policy_task4" {
  name   = "lambda_s3_list_policy_task4"
  policy = data.aws_iam_policy_document.s3_list_policy_doc_task4.json
}

resource "aws_iam_role_policy_attachment" "s3_list_task4" {
  role       = aws_iam_role.lambda_publish_sns_role.name
  policy_arn = aws_iam_policy.s3_list_policy_task4.arn
}

# Lambda
data "archive_file" "lambda_send_bucket_list_to_email" {
  type        = "zip"
  source_file = "${path.module}/lambdas/send_bucket_list_to_email/src/lambda.py"
  output_path = "lambda_send_bucket_list_to_email.zip"
}

resource "aws_lambda_function" "lambda_send_bucket_list_to_email" {
  filename         = "lambda_send_bucket_list_to_email.zip"
  function_name    = "python_tf_task4"
  role             = aws_iam_role.lambda_publish_sns_role.arn
  source_code_hash = data.archive_file.lambda_send_bucket_list_to_email.output_base64sha512
  architectures    = ["arm64"]
  runtime          = "python3.12"
  handler          = "lambda.lambda_handler"
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.email_from_lambda.arn
    }
  }
}
