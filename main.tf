# S3 buckets
# module "epm-nikitsenka-test_bucket" {
#   source      = "./modules/s3_bucket"
#   bucket_name = "epm-nikitsenka-test"
#   tags        = local.common_tags
# }

# output "created_bucket_id" {
#   value = module.epm-nikitsenka-test_bucket.bucket_id
# }

# Lambda function
module "lambda-ini-s3-to-db" {
  source         = "./modules/lambda/ini_from_s3_to_db"
  lambda_name    = "py_tf_s3_to_db"
  s3_bucket_arns = ["arn:aws:s3:::nikitsenka-readonly-storage/*", "arn:aws:s3:::nikitsenka-readonly-storage-policy/*"]
  tags           = local.common_tags
}



