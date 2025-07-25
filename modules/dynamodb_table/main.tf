resource "aws_dynamodb_table" "dynamodb_table" {
  name           = var.table_name
  billing_mode   = var.billing_mode
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity
  hash_key       = "bucket_name"
  range_key      = "key"

  attribute {
    name = "bucket_name"
    type = "S"
  }

  attribute {
    name = "key"
    type = "S"
  }

  tags = var.tags
}