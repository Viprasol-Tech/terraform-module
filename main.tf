locals {
  bucket_name = var.bucket_name_override != null ? var.bucket_name_override : "${var.name}-${var.environment}"

  standard_tags = {
    Name        = local.bucket_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
    Module      = "viprasol-tech/terraform-module"
  }

  # Per-resource tags (var.tags) take precedence over the module's standard tags.
  tags = merge(local.standard_tags, var.tags)

  # Resolve the KMS key ARN used for encryption. When create_kms_key is true we
  # use the key this module manages; otherwise we fall back to the caller-supplied
  # ARN (which may be null for the AWS-managed aws/s3 key).
  effective_kms_key_arn = var.sse_algorithm == "aws:kms" ? (
    var.create_kms_key ? aws_kms_key.this[0].arn : var.kms_key_arn
  ) : null

  # The log delivery target. When create_log_bucket is true the module provisions
  # a dedicated log bucket; otherwise it uses the caller-supplied bucket name.
  log_target_bucket = var.logging_enabled ? (
    var.create_log_bucket ? aws_s3_bucket.logs[0].id : var.log_bucket_name
  ) : null
}

# ---------------------------------------------------------------------------
# Optional customer-managed KMS key
# ---------------------------------------------------------------------------
resource "aws_kms_key" "this" {
  count = var.sse_algorithm == "aws:kms" && var.create_kms_key ? 1 : 0

  description             = "KMS key for S3 bucket ${local.bucket_name}"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_enable_rotation

  tags = local.tags
}

resource "aws_kms_alias" "this" {
  count = var.sse_algorithm == "aws:kms" && var.create_kms_key ? 1 : 0

  name          = "alias/${local.bucket_name}"
  target_key_id = aws_kms_key.this[0].key_id
}

# ---------------------------------------------------------------------------
# Primary bucket
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = local.tags
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status     = var.versioning_enabled ? "Enabled" : "Suspended"
    mfa_delete = var.mfa_delete ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = local.effective_kms_key_arn
    }
    bucket_key_enabled = var.sse_algorithm == "aws:kms" ? var.bucket_key_enabled : false
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = var.block_public_access ? 1 : 0

  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# Lifecycle rules
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  # Lifecycle configuration requires versioning to be configured first.
  depends_on = [aws_s3_bucket_versioning.this]

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [rule.value.expiration_days] : []
        content {
          days = expiration.value
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transitions
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration_days != null ? [rule.value.noncurrent_version_expiration_days] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days != null ? [rule.value.abort_incomplete_multipart_upload_days] : []
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Optional dedicated access-log bucket
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "logs" {
  count = var.logging_enabled && var.create_log_bucket ? 1 : 0

  bucket        = "${local.bucket_name}-logs"
  force_destroy = var.force_destroy

  tags = merge(local.tags, { Purpose = "access-logs" })
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count = var.logging_enabled && var.create_log_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    # Log delivery requires the bucket owner to take ownership of delivered objects.
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count = var.logging_enabled && var.create_log_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count = var.logging_enabled && var.create_log_bucket ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ---------------------------------------------------------------------------
# Access logging
# ---------------------------------------------------------------------------
resource "aws_s3_bucket_logging" "this" {
  count = var.logging_enabled ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = local.log_target_bucket
  target_prefix = var.log_target_prefix
}

# ---------------------------------------------------------------------------
# Optional bucket policy (e.g. enforce TLS-only access)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "this" {
  count = var.attach_policy ? 1 : 0

  # Deny any request that is not made over HTTPS.
  dynamic "statement" {
    for_each = var.enforce_tls ? [1] : []
    content {
      sid       = "DenyInsecureTransport"
      effect    = "Deny"
      actions   = ["s3:*"]
      resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      condition {
        test     = "Bool"
        variable = "aws:SecureTransport"
        values   = ["false"]
      }
    }
  }

  # Caller-supplied additional statements.
  dynamic "statement" {
    for_each = var.policy_statements
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = length(statement.value.resources) > 0 ? statement.value.resources : [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]

      dynamic "principals" {
        for_each = statement.value.principals
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count = var.attach_policy ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this[0].json

  # Ensure the public access block is in place before attaching a policy.
  depends_on = [aws_s3_bucket_public_access_block.this]
}
