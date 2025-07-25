output "sns_topic_arn" {
  description = "The topic's ARN"
  value = aws_sns_topic.email_from_lambda.arn
}