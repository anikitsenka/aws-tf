# Trust policy
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


# IAM role
resource "aws_iam_role" "lambda_read_from_my_buckets_role" {
  description        = "IAM role for lambda function"
  name               = "lambda_read_from_my_buckets_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

# Policy to read and list S3 buckets
data "aws_iam_policy_document" "s3_read_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = concat(var.s3_bucket_arns, [for arn in var.s3_bucket_arns : "${arn}/*"])
  }
}

resource "aws_iam_policy" "s3_read_policy" {
  name   = "lambda_s3_read_policy"
  policy = data.aws_iam_policy_document.s3_read_policy_doc.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "s3_read_file" {
  role       = aws_iam_role.lambda_read_from_my_buckets_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

# Policy to write to DynamoDB tables
data "aws_iam_policy_document" "dynamodb_write_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = var.dynamodb_table_arns
  }
}

resource "aws_iam_policy" "dynamodb_write_policy" {
  name   = "dynamodb_write_policy"
  policy = data.aws_iam_policy_document.dynamodb_write_policy_doc.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "dynamodb_write" {
  role       = aws_iam_role.lambda_read_from_my_buckets_role.name
  policy_arn = aws_iam_policy.dynamodb_write_policy.arn
}

# Lambda function
data "archive_file" "lambda_ini_from_s3_to_db" {
  type        = "zip"
  source_file = "${path.module}/src/lambda.py"
  output_path = "lambda_ini_from_s3_to_db.zip"
}

resource "aws_lambda_function" "lambda_ini_from_s3_to_db" {
  filename         = "lambda_ini_from_s3_to_db.zip"
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda_read_from_my_buckets_role.arn
  source_code_hash = data.archive_file.lambda_ini_from_s3_to_db.output_base64sha512
  architectures    = ["arm64"]
  runtime          = "python3.12"
  timeout          = 10
  layers           = ["arn:aws:lambda:us-east-1:159902866035:layer:aiboto3:1"]
  handler          = "lambda.lambda_handler"
  tags             = var.tags
  environment {
    variables = {
      BUCKET_ARNS = join(",", var.s3_bucket_arns)
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }
}