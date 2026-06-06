# ---------------------------------------------------------------------------
# Naming & identity
# ---------------------------------------------------------------------------
variable "name" {
  description = "Base name used to derive the bucket name. Must be lowercase alphanumeric or hyphens (S3 naming rules)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "The name must be 3-63 characters, lowercase alphanumeric or hyphens, and start/end with an alphanumeric character."
  }
}

variable "bucket_name_override" {
  description = "Explicit bucket name. When set, it is used verbatim and var.name/var.environment are not concatenated. Must still satisfy S3 naming rules."
  type        = string
  default     = null

  validation {
    condition     = var.bucket_name_override == null || can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name_override))
    error_message = "The bucket_name_override must be 3-63 characters, lowercase alphanumeric, hyphens or dots, and start/end with an alphanumeric character."
  }
}

variable "environment" {
  description = "Deployment environment label applied as a tag and appended to resource names."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Team or individual responsible for the resource. Applied as the Owner tag."
  type        = string
  default     = "platform"
}

variable "tags" {
  description = "Additional tags merged onto the module's standard tags. Per-resource tags win on key collisions."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Bucket behaviour
# ---------------------------------------------------------------------------
variable "force_destroy" {
  description = "If true, the bucket (and the log bucket, if created) and all their objects can be destroyed without being emptied first. Use with caution."
  type        = bool
  default     = false
}

variable "object_ownership" {
  description = "S3 Object Ownership setting. One of BucketOwnerEnforced (ACLs disabled, recommended), BucketOwnerPreferred, or ObjectWriter."
  type        = string
  default     = "BucketOwnerEnforced"

  validation {
    condition     = contains(["BucketOwnerEnforced", "BucketOwnerPreferred", "ObjectWriter"], var.object_ownership)
    error_message = "The object_ownership must be one of: BucketOwnerEnforced, BucketOwnerPreferred, ObjectWriter."
  }
}

variable "versioning_enabled" {
  description = "Whether to enable object versioning on the bucket."
  type        = bool
  default     = true
}

variable "mfa_delete" {
  description = "Whether to require MFA to delete object versions. Requires versioning and can only be toggled by the bucket/root owner via CLI."
  type        = bool
  default     = false
}

variable "block_public_access" {
  description = "Whether to enable all four S3 public access block settings on the bucket."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Encryption
# ---------------------------------------------------------------------------
variable "sse_algorithm" {
  description = "Server-side encryption algorithm for the bucket. One of AES256 or aws:kms."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "The sse_algorithm must be either AES256 or aws:kms."
  }
}

variable "create_kms_key" {
  description = "When sse_algorithm is aws:kms, create and manage a dedicated KMS key (with alias) instead of supplying one via kms_key_arn."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "ARN of an existing KMS key to use when sse_algorithm is aws:kms and create_kms_key is false. Null uses the AWS-managed aws/s3 key. Ignored for AES256."
  type        = string
  default     = null
}

variable "kms_key_deletion_window_in_days" {
  description = "Waiting period before a module-managed KMS key is deleted. Only used when create_kms_key is true."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window_in_days >= 7 && var.kms_key_deletion_window_in_days <= 30
    error_message = "The kms_key_deletion_window_in_days must be between 7 and 30."
  }
}

variable "kms_key_enable_rotation" {
  description = "Whether to enable automatic annual key rotation on a module-managed KMS key."
  type        = bool
  default     = true
}

variable "bucket_key_enabled" {
  description = "Whether to use an S3 Bucket Key to reduce KMS request costs. Only applies when sse_algorithm is aws:kms."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Lifecycle rules
# ---------------------------------------------------------------------------
variable "lifecycle_rules" {
  description = "List of lifecycle rules. Each rule supports transitions, expiration, noncurrent-version handling, and incomplete-multipart cleanup."
  type = list(object({
    id              = string
    enabled         = optional(bool, true)
    prefix          = optional(string, "")
    expiration_days = optional(number)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    noncurrent_version_transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    noncurrent_version_expiration_days     = optional(number)
    abort_incomplete_multipart_upload_days = optional(number)
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.lifecycle_rules : alltrue([
        for t in r.transitions : contains(
          ["STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER", "GLACIER_IR", "DEEP_ARCHIVE"],
          t.storage_class
        )
      ])
    ])
    error_message = "Each transition storage_class must be one of: STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, GLACIER, GLACIER_IR, DEEP_ARCHIVE."
  }
}

# ---------------------------------------------------------------------------
# Access logging
# ---------------------------------------------------------------------------
variable "logging_enabled" {
  description = "Whether to enable S3 server access logging for the bucket."
  type        = bool
  default     = false
}

variable "create_log_bucket" {
  description = "When logging is enabled, create a dedicated '<bucket>-logs' bucket as the delivery target. If false, log_bucket_name must be supplied."
  type        = bool
  default     = true
}

variable "log_bucket_name" {
  description = "Name of an existing bucket to deliver access logs to. Required when logging_enabled is true and create_log_bucket is false."
  type        = string
  default     = null
}

variable "log_target_prefix" {
  description = "Key prefix under which access logs are written in the target bucket."
  type        = string
  default     = "log/"
}

# ---------------------------------------------------------------------------
# Bucket policy
# ---------------------------------------------------------------------------
variable "attach_policy" {
  description = "Whether to attach a bucket policy assembled from enforce_tls and policy_statements."
  type        = bool
  default     = false
}

variable "enforce_tls" {
  description = "When attach_policy is true, add a statement denying any request not made over HTTPS (aws:SecureTransport = false)."
  type        = bool
  default     = true
}

variable "policy_statements" {
  description = "Additional IAM policy statements to include in the bucket policy. Resources default to the bucket and its objects when left empty."
  type = list(object({
    sid       = string
    effect    = optional(string, "Allow")
    actions   = list(string)
    resources = optional(list(string), [])
    principals = optional(list(object({
      type        = string
      identifiers = list(string)
    })), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for s in var.policy_statements : contains(["Allow", "Deny"], s.effect)
    ])
    error_message = "Each policy_statements effect must be either Allow or Deny."
  }
}
