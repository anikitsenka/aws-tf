resource "aws_s3_bucket" "s3-test" {
  bucket = "kitikeka-test"
  tags = {
    Name = "kitikeka-test"
  }
}
