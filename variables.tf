variable "name" {
  description = "Base name used to derive the bucket name. Must be lowercase alphanumeric or hyphens (S3 naming rules)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "The name must be 3-63 characters, lowercase alphanumeric or hyphens, and start/end with an alphanumeric character."
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

variable "force_destroy" {
  description = "If true, the bucket and all its objects can be destroyed without being emptied first. Use with caution."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Whether to enable object versioning on the bucket."
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm for the bucket. One of AES256 or aws:kms."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "The sse_algorithm must be either AES256 or aws:kms."
  }
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to use when sse_algorithm is aws:kms. Ignored for AES256."
  type        = string
  default     = null
}

variable "block_public_access" {
  description = "Whether to enable all four S3 public access block settings on the bucket."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags merged onto the module's standard tags. Per-resource tags win on key collisions."
  type        = map(string)
  default     = {}
}
