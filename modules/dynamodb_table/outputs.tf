output "table_id" {
  description = "The ID of the DynamoDB table."
  value       = aws_dynamodb_table.dynamodb_table.id
}

output "table_arn" {
  description = "The ARN of the DynamoDB Table."
  value       = aws_dynamodb_table.dynamodb_table.arn
}