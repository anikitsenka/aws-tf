# S3 buckets for ini files
module "epm-ini-1" {
  source      = "./modules/s3_bucket"
  bucket_name = "epm-ini-1"
  tags        = local.common_tags
}

module "epm-ini-2" {
  source      = "./modules/s3_bucket"
  bucket_name = "epm-ini-2"
  tags        = local.common_tags
}

# module "epm-ini-3" {
#   source      = "./modules/s3_bucket"
#   bucket_name = "epm-ini-3"
#   tags        = local.common_tags
# }

# Upload ini files to buckets
resource "aws_s3_object" "upload_content_1" {
  bucket       = module.epm-ini-1.bucket_id
  for_each     = fileset("buckets_content/epm-ini-1", "**/*.*")
  key          = each.value
  source       = "buckets_content/epm-ini-1/${each.value}"
  content_type = each.value
}

resource "aws_s3_object" "upload_content_2" {
  bucket       = module.epm-ini-2.bucket_id
  for_each     = fileset("buckets_content/epm-ini-2", "**/*.*")
  key          = each.value
  source       = "buckets_content/epm-ini-2/${each.value}"
  content_type = each.value
}

# resource "aws_s3_object" "upload_content_3" {
#   bucket       = module.epm-ini-3.bucket_id
#   for_each     = fileset("buckets_content/epm-ini-3", "**/*.*")
#   key          = each.value
#   source       = "buckets_content/epm-ini-3/${each.value}"
#   content_type = each.value
# }

# DynamoDB tables
module "dynamodb_table_even" {
  source       = "./modules/dynamodb_table"
  table_name   = "even_table"
  billing_mode = "PAY_PER_REQUEST"
  tags         = local.common_tags
}

module "dynamodb_table_odd" {
  source       = "./modules/dynamodb_table"
  table_name   = "odd_table"
  billing_mode = "PAY_PER_REQUEST"
  tags         = local.common_tags
}

# Lambda function
module "lambda-ini-s3-to-db" {
  source              = "./modules/lambda/ini_from_s3_to_db"
  lambda_name         = "py_tf_s3_to_db"
  s3_bucket_arns      = [module.epm-ini-1.bucket_arn, module.epm-ini-2.bucket_arn]
  sns_topic_arn       = module.sns-to-email.sns_topic_arn
  dynamodb_table_arns = [module.dynamodb_table_odd.table_arn, module.dynamodb_table_even.table_arn]
  tags                = local.common_tags
}

# SNS publisher
module "sns-to-email" {
  source                       = "./modules/lambda_to_sns"
  lambda_publish_sns_role_name = module.lambda-ini-s3-to-db.role_name
  tags                         = local.common_tags
}