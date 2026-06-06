# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-06-06

### Added

- **Lifecycle rules** — new `lifecycle_rules` input (list of objects) supporting
  storage-class transitions, current/noncurrent version expiration, noncurrent
  version transitions, and incomplete-multipart-upload cleanup, with validation
  on allowed storage classes.
- **Server access logging** — `logging_enabled`, `create_log_bucket`,
  `log_bucket_name`, and `log_target_prefix` inputs. The module can provision a
  dedicated, secured `<bucket>-logs` bucket or deliver to an existing one.
- **Optional module-managed KMS key** — `create_kms_key`,
  `kms_key_deletion_window_in_days`, `kms_key_enable_rotation`, and
  `bucket_key_enabled` inputs. When enabled, the module creates a KMS key with an
  alias and (optionally) automatic rotation.
- **Bucket policy toggle** — `attach_policy`, `enforce_tls`, and
  `policy_statements` inputs. Assembles a policy via `aws_iam_policy_document`
  that can deny non-TLS access and merge in caller-supplied statements.
- **Object ownership control** — `object_ownership` input (defaults to
  `BucketOwnerEnforced`, disabling ACLs).
- **MFA delete** — `mfa_delete` input on the versioning configuration.
- **Bucket name override** — `bucket_name_override` input to set an explicit
  bucket name instead of the derived `name-environment` value.
- **Richer outputs** — `bucket_hosted_zone_id`, `sse_algorithm`, `kms_key_arn`,
  `kms_key_id`, `kms_alias_name`, `log_bucket_id`, `log_target_bucket`,
  `lifecycle_rule_ids`, and `policy_attached`.
- **Second example** — `examples/minimal/` demonstrating the smallest viable
  usage alongside the expanded `examples/complete/`.

### Changed

- `examples/complete/` now exercises the KMS key, logging, lifecycle, and policy
  features end to end.
- Encryption block now honours `bucket_key_enabled` and resolves the effective
  KMS key ARN (module-managed, caller-supplied, or AWS-managed) via a local.
- README rewritten to flagship standard with full input/output tables, an
  examples section, a parameters reference, a roadmap, and an FAQ.

## [0.1.0] - 2025-05-01

### Added

- Initial release: tagged S3 bucket module with versioning, server-side
  encryption (AES256 / aws:kms), public-access blocking, typed variables with
  validation, a complete output surface, and a runnable example.
