# Setup SNS
resource "aws_sns_topic" "email_from_lambda" {
  name = "email_from_lambda"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.email_from_lambda.arn
  protocol  = "email"
  endpoint  = var.endpoint_email
}

# IAM SNS
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
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "attach_publish_sns_policy" {
  role       = var.lambda_publish_sns_role_name
  policy_arn = aws_iam_policy.allow_publish_sns_policy.arn
}
