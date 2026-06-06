output "bucket_id" {
  description = "The name (ID) of the S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The global domain name of the bucket (bucket.s3.amazonaws.com)."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The region-specific domain name of the bucket."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_region" {
  description = "The AWS region the bucket resides in."
  value       = aws_s3_bucket.this.region
}

output "versioning_status" {
  description = "The configured versioning status of the bucket."
  value       = aws_s3_bucket_versioning.this.versioning_configuration[0].status
}

output "tags" {
  description = "The full set of tags applied to the bucket."
  value       = aws_s3_bucket.this.tags_all
}
