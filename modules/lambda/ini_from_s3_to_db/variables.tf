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