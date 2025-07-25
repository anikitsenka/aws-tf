output "lambda_id" {
  description = "The ID of the lambda."
  value       = aws_lambda_function.lambda_ini_from_s3_to_db.id
}

output "lambda_arn" {
  description = "The ARN of the lambda."
  value       = aws_lambda_function.lambda_ini_from_s3_to_db.arn
}

output "role_arn" {
  description = "The ARN of the corresponding role"
  value       = aws_iam_role.lambda_read_from_my_buckets_role.arn
}

output "role_name" {
  description = "The name of the corresponding role"
  value       = aws_iam_role.lambda_read_from_my_buckets_role.name
}