variable "table_name" {
  description = "The name of the DynamoDB table"
  type        = string
}

variable "billing_mode" {
  description = "Billing mode of the DynamoDB table"
  type        = string
}

variable "read_capacity" {
  description = "Read capacity units for the DynamoDB table"
  type        = number
  default     = null
}

variable "write_capacity" {
  description = "Write capacity units for the DynamoDB table"
  type        = number
  default     = null
}

variable "tags" {
  description = "Tags to apply to the DynamoDB table"
  type        = map(any)
  default     = {}
}