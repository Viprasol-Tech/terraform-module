<div align="center">
  <img src="docs/assets/logo.png" alt="Viprasol Tech" width="120" />

  <h1>Terraform Module — Tagged, Secure S3 Bucket</h1>

  <p><strong>A reusable, opinionated Terraform module for provisioning a consistently tagged, encrypted, versioned S3 bucket — with optional lifecycle rules, access logging, a managed KMS key, and a bucket policy.</strong></p>

  <p><em>Built and maintained by Viprasol Tech.</em></p>

  <p>
    <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License: MIT" />
    <img src="https://img.shields.io/badge/terraform-%3E%3D1.3-7B42BC.svg" alt="Terraform >= 1.3" />
    <img src="https://img.shields.io/badge/provider-aws%20%3E%3D5.0-FF9900.svg" alt="AWS Provider >= 5.0" />
    <img src="https://img.shields.io/badge/version-0.2.0-blue.svg" alt="Version 0.2.0" />
    <a href="https://github.com/Viprasol-Tech/terraform-module/issues"><img src="https://img.shields.io/github/issues/Viprasol-Tech/terraform-module.svg" alt="Issues" /></a>
    <a href="https://github.com/Viprasol-Tech/terraform-module/stargazers"><img src="https://img.shields.io/github/stars/Viprasol-Tech/terraform-module.svg" alt="Stars" /></a>
  </p>
</div>

---

## Overview

This module is a clean, production-shaped example of a **reusable Terraform module**: typed variables with validation, computed locals, a focused set of related resources wired with `count`/`dynamic` blocks, and a complete output surface. It provisions an S3 bucket with a derived, environment-suffixed name and a standard tagging convention, then layers on versioning, server-side encryption, public-access blocking, lifecycle rules, access logging, an optional customer-managed KMS key, and an optional bucket policy.

Everything beyond the required `name` input is **secure by default** and **opt-in for advanced behaviour** — so the minimal example is one line, while the complete example exercises every feature.

Use it as-is, or fork it as a template for your own internal modules.

## ✨ Features

- 🏷️ **Consistent tagging** — every bucket gets `Name`, `Environment`, `Owner`, `ManagedBy`, and `Module` tags; callers can merge in their own.
- ✅ **Typed inputs with validation** — names, environment, encryption, ownership, lifecycle storage classes, and policy effects are validated at plan time so misconfigurations fail fast.
- 🔐 **Encryption by default** — `AES256` out of the box, or `aws:kms` using the AWS-managed key, a caller-supplied key ARN, or a **module-managed KMS key** with alias and automatic rotation.
- 🕒 **Versioning & MFA delete** — versioning enabled by default and switchable per environment, with optional MFA-delete enforcement.
- ♻️ **Lifecycle rules** — transitions across storage classes, expiration, noncurrent-version handling, and incomplete-multipart cleanup, all driven from a single list variable.
- 📜 **Access logging** — deliver server access logs into a dedicated module-created log bucket or an existing one.
- 🛡️ **Bucket policy toggle** — optionally enforce TLS-only access and merge in your own statements.
- 🚫 **Secure by default** — all four S3 public-access-block settings on, and ACLs disabled (`BucketOwnerEnforced`) unless explicitly changed.
- 📤 **Complete outputs** — bucket ID, ARN, domain names, region, hosted zone, versioning status, encryption details, KMS metadata, logging targets, lifecycle rule IDs, and resolved tags.
- 🧪 **Two runnable examples** — `examples/minimal/` and `examples/complete/`.

## Repository layout

```
.
├── main.tf                    # Resources + locals (bucket, KMS, versioning, SSE, PAB, lifecycle, logging, policy)
├── variables.tf               # Typed input variables with descriptions, defaults, validation
├── outputs.tf                 # Module outputs
├── versions.tf                # Terraform + provider version constraints
├── CHANGELOG.md               # Keep a Changelog history
└── examples/
    ├── minimal/
    │   └── main.tf            # Smallest viable usage (only `name`)
    └── complete/
        └── main.tf            # End-to-end usage exercising every feature
```

## How to install & run on Terraform

> Requires [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.3` and AWS credentials configured (e.g. via `AWS_PROFILE` or environment variables). Provisioning resources incurs real AWS costs.

Run one of the bundled examples:

```bash
cd examples/minimal      # or examples/complete
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Tear it down when you are done:

```bash
terraform destroy
```

## Usage

Reference the module from your own configuration. The minimal call needs only `name`:

```hcl
module "bucket" {
  source = "github.com/Viprasol-Tech/terraform-module"

  name = "my-app-assets"
}
```

A more complete call with a module-managed KMS key, logging, and lifecycle rules:

```hcl
module "tagged_bucket" {
  source = "github.com/Viprasol-Tech/terraform-module"

  name        = "my-app-assets"
  environment = "prod"
  owner       = "data-platform"

  sse_algorithm  = "aws:kms"
  create_kms_key = true

  logging_enabled   = true
  create_log_bucket = true

  lifecycle_rules = [
    {
      id              = "archive-and-expire"
      expiration_days = 365
      transitions = [
        { days = 30, storage_class = "STANDARD_IA" },
        { days = 90, storage_class = "GLACIER" },
      ]
    }
  ]

  attach_policy = true
  enforce_tls   = true

  tags = {
    CostCenter = "1234"
    Project    = "billing"
  }
}

output "bucket_arn" {
  value = module.tagged_bucket.bucket_arn
}
```

## Examples

| Example                                       | What it shows                                                                                       |
| --------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| [`examples/minimal`](examples/minimal)        | The smallest viable call — only the required `name`, relying on secure defaults.                     |
| [`examples/complete`](examples/complete)      | Module-managed KMS key with rotation, access logging into a dedicated bucket, a tiered lifecycle policy, and a TLS-enforcing bucket policy. |

## Inputs

| Name                              | Description                                                                                          | Type                  | Default                | Required |
| --------------------------------- | -------------------------------------------------------------------------------------------------- | --------------------- | ---------------------- | :------: |
| `name`                            | Base name used to derive the bucket name (S3 naming rules apply).                                    | `string`              | n/a                    |   yes    |
| `bucket_name_override`            | Explicit bucket name used verbatim instead of `name-environment`.                                    | `string`              | `null`                 |    no    |
| `environment`                     | Deployment environment; tagged and appended to the bucket name.                                      | `string`              | `"dev"`                |    no    |
| `owner`                           | Team or individual responsible; applied as the `Owner` tag.                                          | `string`              | `"platform"`           |    no    |
| `tags`                            | Extra tags merged onto the module's standard tags.                                                   | `map(string)`         | `{}`                   |    no    |
| `force_destroy`                   | Allow destroying a non-empty bucket (and log bucket). Use with caution.                              | `bool`                | `false`                |    no    |
| `object_ownership`                | S3 Object Ownership: `BucketOwnerEnforced`, `BucketOwnerPreferred`, or `ObjectWriter`.               | `string`              | `"BucketOwnerEnforced"`|    no    |
| `versioning_enabled`              | Enable object versioning on the bucket.                                                              | `bool`                | `true`                 |    no    |
| `mfa_delete`                      | Require MFA to delete object versions.                                                               | `bool`                | `false`                |    no    |
| `block_public_access`             | Enable all four S3 public-access-block settings.                                                     | `bool`                | `true`                 |    no    |
| `sse_algorithm`                   | Server-side encryption algorithm: `AES256` or `aws:kms`.                                             | `string`              | `"AES256"`             |    no    |
| `create_kms_key`                  | Create and manage a dedicated KMS key (with alias) when using `aws:kms`.                             | `bool`                | `false`                |    no    |
| `kms_key_arn`                     | Existing KMS key ARN used with `aws:kms` when `create_kms_key` is false (`null` = AWS-managed key).  | `string`              | `null`                 |    no    |
| `kms_key_deletion_window_in_days` | Deletion window for a module-managed KMS key (7–30).                                                 | `number`              | `30`                   |    no    |
| `kms_key_enable_rotation`         | Enable annual rotation on a module-managed KMS key.                                                  | `bool`                | `true`                 |    no    |
| `bucket_key_enabled`              | Use an S3 Bucket Key to reduce KMS costs (only with `aws:kms`).                                      | `bool`                | `true`                 |    no    |
| `lifecycle_rules`                 | List of lifecycle rule objects (transitions, expiration, noncurrent handling, multipart cleanup).   | `list(object)`        | `[]`                   |    no    |
| `logging_enabled`                 | Enable S3 server access logging.                                                                     | `bool`                | `false`                |    no    |
| `create_log_bucket`               | Create a dedicated `<bucket>-logs` bucket as the log target.                                         | `bool`                | `true`                 |    no    |
| `log_bucket_name`                 | Existing bucket to receive logs (required when `create_log_bucket` is false).                        | `string`              | `null`                 |    no    |
| `log_target_prefix`               | Key prefix for delivered access logs.                                                                | `string`              | `"log/"`               |    no    |
| `attach_policy`                   | Attach a bucket policy assembled from `enforce_tls` and `policy_statements`.                         | `bool`                | `false`                |    no    |
| `enforce_tls`                     | Add a statement denying non-HTTPS requests when a policy is attached.                                | `bool`                | `true`                 |    no    |
| `policy_statements`               | Additional IAM policy statements to merge into the bucket policy.                                    | `list(object)`        | `[]`                   |    no    |

### Lifecycle rule object

Each item of `lifecycle_rules` accepts:

| Field                                    | Type           | Default | Notes                                                                 |
| ---------------------------------------- | -------------- | ------- | --------------------------------------------------------------------- |
| `id`                                     | `string`       | n/a     | Unique rule identifier.                                               |
| `enabled`                                | `bool`         | `true`  | Whether the rule is active.                                          |
| `prefix`                                 | `string`       | `""`    | Object key prefix the rule applies to.                              |
| `expiration_days`                        | `number`       | `null`  | Expire current objects after N days.                                 |
| `transitions`                            | `list(object)` | `[]`    | `{ days, storage_class }` transitions for current objects.           |
| `noncurrent_version_transitions`         | `list(object)` | `[]`    | `{ days, storage_class }` transitions for noncurrent versions.       |
| `noncurrent_version_expiration_days`     | `number`       | `null`  | Expire noncurrent versions after N days.                             |
| `abort_incomplete_multipart_upload_days` | `number`       | `null`  | Abort incomplete multipart uploads after N days.                     |

Valid `storage_class` values: `STANDARD_IA`, `ONEZONE_IA`, `INTELLIGENT_TIERING`, `GLACIER`, `GLACIER_IR`, `DEEP_ARCHIVE`.

### Validation rules

- `name` — 3–63 chars, lowercase alphanumeric or hyphens, must start and end alphanumeric.
- `bucket_name_override` — same rules, additionally allowing dots.
- `environment` — one of `dev`, `staging`, `prod`.
- `object_ownership` — one of `BucketOwnerEnforced`, `BucketOwnerPreferred`, `ObjectWriter`.
- `sse_algorithm` — one of `AES256`, `aws:kms`.
- `kms_key_deletion_window_in_days` — between 7 and 30.
- `lifecycle_rules[*].transitions[*].storage_class` — a valid S3 storage class (see above).
- `policy_statements[*].effect` — one of `Allow`, `Deny`.

## Outputs

| Name                          | Description                                                                          |
| ----------------------------- | ------------------------------------------------------------------------------------ |
| `bucket_id`                   | The name (ID) of the S3 bucket.                                                       |
| `bucket_arn`                  | The ARN of the S3 bucket.                                                             |
| `bucket_domain_name`          | The global domain name of the bucket.                                                 |
| `bucket_regional_domain_name` | The region-specific domain name of the bucket.                                        |
| `bucket_region`               | The AWS region the bucket resides in.                                                 |
| `bucket_hosted_zone_id`       | The Route 53 hosted zone ID for the bucket's region.                                  |
| `versioning_status`           | The configured versioning status (`Enabled`/`Suspended`).                             |
| `sse_algorithm`               | The server-side encryption algorithm applied.                                         |
| `kms_key_arn`                 | The KMS key ARN used for encryption (or `null` for AES256/AWS-managed).               |
| `kms_key_id`                  | The ID of the module-managed KMS key (or `null`).                                     |
| `kms_alias_name`              | The alias of the module-managed KMS key (or `null`).                                  |
| `log_bucket_id`               | The name of the module-created access-log bucket (or `null`).                         |
| `log_target_bucket`          | The bucket access logs are delivered to (or `null` when logging is disabled).         |
| `lifecycle_rule_ids`          | The IDs of all configured lifecycle rules.                                            |
| `policy_attached`             | Whether a bucket policy was attached by the module.                                   |
| `tags`                        | The full resolved set of tags applied to the bucket.                                  |

## 🗺️ Roadmap

- [x] Lifecycle rules with transitions, expiration, and multipart cleanup
- [x] Access logging with optional dedicated log bucket
- [x] Optional module-managed KMS key with rotation
- [x] Bucket policy toggle with TLS enforcement
- [x] Minimal + complete examples
- [ ] Cross-region replication support
- [ ] S3 event notifications (SNS/SQS/Lambda) wiring
- [ ] CloudFront origin access control helper output
- [ ] Optional object-lock (WORM) configuration

## ❓ FAQ

**Why is the bucket name derived from `name` and `environment`?**
To keep bucket names predictable and environment-scoped. Set `bucket_name_override` if you need an exact name.

**Do I have to manage a KMS key myself?**
No. With `sse_algorithm = "AES256"` (the default) you get SSE-S3 for free. With `aws:kms` you can use the AWS-managed `aws/s3` key (`kms_key_arn = null`), bring your own key, or let the module create one (`create_kms_key = true`).

**Why are ACLs disabled by default?**
`object_ownership = "BucketOwnerEnforced"` disables ACLs, which is the AWS-recommended posture. Logging into a module-created log bucket still works because that bucket uses `BucketOwnerPreferred` internally.

**Can I attach my own policy statements?**
Yes — set `attach_policy = true` and pass `policy_statements`. They are merged with the optional TLS-enforcement statement.

## Contributing

Contributions are welcome. Please open an issue to discuss substantial changes first, then submit a pull request. Keep HCL formatted with `terraform fmt`, validated with `terraform validate`, and add or update the examples when changing the input/output surface.

## Disclaimer

This module is provided for educational and reference purposes. Provisioning cloud infrastructure incurs real costs and can affect production systems. Always run `terraform plan` and review changes before `apply`. You are responsible for the resources created in your own AWS account. This is not financial advice.

## Contact — Viprasol Tech Private Limited

- Website: [viprasol.com](https://viprasol.com)
- Email: [support@viprasol.com](mailto:support@viprasol.com)
- Telegram: [t.me/viprasol_help](https://t.me/viprasol_help) | WhatsApp: +91 96336 52112
- GitHub: [@Viprasol-Tech](https://github.com/Viprasol-Tech) | [LinkedIn](https://www.linkedin.com/in/viprasol/) | X [@viprasol](https://twitter.com/viprasol)

## License

[MIT](LICENSE) (c) 2025 Viprasol Tech Private Limited
