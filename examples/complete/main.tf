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

# Consume the module from the repository root.
module "tagged_bucket" {
  source = "../../"

  name               = "viprasol-app-assets"
  environment        = "prod"
  owner              = "data-platform"
  versioning_enabled = true
  sse_algorithm      = "AES256"

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

output "bucket_tags" {
  description = "Tags applied to the bucket."
  value       = module.tagged_bucket.tags
}
