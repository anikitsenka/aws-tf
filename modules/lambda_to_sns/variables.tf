variable "endpoint_email" {
  description = "E-mail address to send to"
  type        = string
  default     = "andrei_nikitsenka@epam.com"
}

variable "lambda_publish_sns_role_name" {
  description = "Role name to attach policy to"
  type        = string
}

variable "tags" {
  description = "The tags for the S3 bucket."
  type        = map(any)
  default     = {}
}