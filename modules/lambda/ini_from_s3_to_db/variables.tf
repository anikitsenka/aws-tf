variable "lambda_name" {
  description = "The name of the lambda function."
  type        = string
}

variable "tags" {
  description = "The tags for the S3 bucket."
  type        = map(any)
  default     = {}
}

variable "s3_bucket_arns" {
  description = "The list of bucket ARNs to read from"
  type        = list(string)
}

variable "dynamodb_table_arns" {
  description = "The list of DynamoDB ARNs to put to"
  type        = list(string)
}

variable "sns_topic_arn" {
  description = "The ARN of SNS topic"
  type        = string
}