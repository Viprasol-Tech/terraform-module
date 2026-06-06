terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region to deploy the example bucket into."
  type        = string
  default     = "us-east-1"
}

# Exercises every feature of the module: a module-managed KMS key with rotation,
# server access logging into a dedicated log bucket, a tiered lifecycle policy,
# and a TLS-enforcing bucket policy.
module "tagged_bucket" {
  source = "../../"

  name        = "viprasol-app-assets"
  environment = "prod"
  owner       = "data-platform"

  # Behaviour
  versioning_enabled = true
  object_ownership   = "BucketOwnerEnforced"

  # Encryption with a dedicated, rotating KMS key managed by the module.
  sse_algorithm           = "aws:kms"
  create_kms_key          = true
  kms_key_enable_rotation = true
  bucket_key_enabled      = true

  # Server access logging into a module-created '<bucket>-logs' bucket.
  logging_enabled   = true
  create_log_bucket = true
  log_target_prefix = "s3-access-logs/"

  # Tiered lifecycle: warm -> IA -> Glacier, expire old noncurrent versions,
  # and clean up incomplete multipart uploads.
  lifecycle_rules = [
    {
      id              = "archive-and-expire"
      enabled         = true
      prefix          = ""
      expiration_days = 365
      transitions = [
        { days = 30, storage_class = "STANDARD_IA" },
        { days = 90, storage_class = "GLACIER" },
      ]
      noncurrent_version_transitions = [
        { days = 30, storage_class = "GLACIER" },
      ]
      noncurrent_version_expiration_days     = 180
      abort_incomplete_multipart_upload_days = 7
    },
    {
      id              = "expire-tmp"
      enabled         = true
      prefix          = "tmp/"
      expiration_days = 7
    },
  ]

  # Bucket policy: enforce TLS plus an explicit read grant for an analytics role.
  attach_policy = true
  enforce_tls   = true
  policy_statements = [
    {
      sid     = "AllowAnalyticsRead"
      effect  = "Allow"
      actions = ["s3:GetObject", "s3:ListBucket"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::111122223333:role/analytics"]
        }
      ]
    }
  ]

  tags = {
    CostCenter = "1234"
    Project    = "labelled-resource-demo"
  }
}

output "bucket_arn" {
  description = "ARN of the bucket created by the module."
  value       = module.tagged_bucket.bucket_arn
}

output "bucket_id" {
  description = "Name of the bucket created by the module."
  value       = module.tagged_bucket.bucket_id
}

output "kms_key_arn" {
  description = "ARN of the module-managed KMS key."
  value       = module.tagged_bucket.kms_key_arn
}

output "log_bucket_id" {
  description = "Name of the access-log bucket."
  value       = module.tagged_bucket.log_bucket_id
}

output "bucket_tags" {
  description = "Tags applied to the bucket."
  value       = module.tagged_bucket.tags
}
