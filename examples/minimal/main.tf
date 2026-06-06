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

# Smallest viable usage: only the required `name` input. Everything else falls
# back to the module's secure defaults (AES256 encryption, versioning on,
# public access blocked, ACLs disabled).
module "bucket" {
  source = "../../"

  name = "viprasol-minimal-demo"
}

output "bucket_id" {
  description = "Name of the bucket created by the module."
  value       = module.bucket.bucket_id
}

output "bucket_arn" {
  description = "ARN of the bucket created by the module."
  value       = module.bucket.bucket_arn
}
