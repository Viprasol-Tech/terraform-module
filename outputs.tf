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

output "bucket_hosted_zone_id" {
  description = "The Route 53 hosted zone ID for the bucket's region, useful for alias records."
  value       = aws_s3_bucket.this.hosted_zone_id
}

output "versioning_status" {
  description = "The configured versioning status of the bucket."
  value       = aws_s3_bucket_versioning.this.versioning_configuration[0].status
}

output "sse_algorithm" {
  description = "The server-side encryption algorithm applied to the bucket."
  value       = var.sse_algorithm
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for encryption (module-managed, caller-supplied, or null for AES256/aws-managed)."
  value       = local.effective_kms_key_arn
}

output "kms_key_id" {
  description = "The ID of the module-managed KMS key, or null when one was not created."
  value       = var.sse_algorithm == "aws:kms" && var.create_kms_key ? aws_kms_key.this[0].key_id : null
}

output "kms_alias_name" {
  description = "The alias of the module-managed KMS key, or null when one was not created."
  value       = var.sse_algorithm == "aws:kms" && var.create_kms_key ? aws_kms_alias.this[0].name : null
}

output "log_bucket_id" {
  description = "The name of the access-log bucket, or null when logging is disabled or an external bucket is used."
  value       = var.logging_enabled && var.create_log_bucket ? aws_s3_bucket.logs[0].id : null
}

output "log_target_bucket" {
  description = "The bucket access logs are delivered to (module-managed or caller-supplied), or null when logging is disabled."
  value       = local.log_target_bucket
}

output "lifecycle_rule_ids" {
  description = "The IDs of all configured lifecycle rules."
  value       = [for r in var.lifecycle_rules : r.id]
}

output "policy_attached" {
  description = "Whether a bucket policy was attached by the module."
  value       = var.attach_policy
}

output "tags" {
  description = "The full set of tags applied to the bucket."
  value       = aws_s3_bucket.this.tags_all
}
