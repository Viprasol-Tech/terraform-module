<div align="center">
  <img src="docs/assets/logo.png" alt="Viprasol Tech" width="120" />

  <h1>Terraform Module — Tagged S3 Bucket</h1>

  <p><strong>A reusable, opinionated Terraform module for provisioning a consistently tagged, encrypted, versioned S3 bucket.</strong></p>

  <p><em>Built and maintained by Viprasol Tech.</em></p>

  <p>
    <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License: MIT" />
    <img src="https://img.shields.io/badge/terraform-%3E%3D1.3-7B42BC.svg" alt="Terraform >= 1.3" />
    <img src="https://img.shields.io/badge/provider-aws%20%3E%3D5.0-FF9900.svg" alt="AWS Provider >= 5.0" />
    <a href="https://github.com/Viprasol-Tech/terraform-module/issues"><img src="https://img.shields.io/github/issues/Viprasol-Tech/terraform-module.svg" alt="Issues" /></a>
    <a href="https://github.com/Viprasol-Tech/terraform-module/stargazers"><img src="https://img.shields.io/github/stars/Viprasol-Tech/terraform-module.svg" alt="Stars" /></a>
  </p>
</div>

---

## Overview

This module is a clean, production-shaped example of a **reusable Terraform module**: typed variables with validation, computed locals, a small set of related resources, and a complete output surface. It provisions an S3 bucket with a derived, environment-suffixed name and a standard tagging convention, then layers on versioning, server-side encryption, and public-access blocking.

Use it as-is, or fork it as a template for your own internal modules.

## Features

- **Consistent tagging** — every bucket gets `Name`, `Environment`, `Owner`, `ManagedBy`, and `Module` tags; callers can merge in their own.
- **Typed inputs with validation** — `name`, `environment`, and `sse_algorithm` are validated at plan time so misconfigurations fail fast.
- **Encryption by default** — `AES256` out of the box, or `aws:kms` with a supplied key ARN (bucket keys auto-enabled for KMS).
- **Versioning toggle** — enabled by default, switchable per environment.
- **Secure by default** — all four S3 public-access-block settings are on unless explicitly disabled.
- **Complete outputs** — bucket ID, ARN, domain names, region, versioning status, and resolved tags.
- **A runnable example** under `examples/complete/`.

## Repository layout

```
.
├── main.tf                    # Resources + locals (bucket, versioning, SSE, public-access block)
├── variables.tf               # Typed input variables with descriptions, defaults, validation
├── outputs.tf                 # Module outputs
├── versions.tf                # Terraform + provider version constraints
└── examples/
    └── complete/
        └── main.tf            # End-to-end usage example
```

## Quickstart

> Requires [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.3` and AWS credentials configured (e.g. via `AWS_PROFILE` or environment variables).

Run the bundled example:

```bash
cd examples/complete
terraform init
terraform plan
terraform apply
```

Tear it down when you are done:

```bash
terraform destroy
```

## Usage

Reference the module from your own configuration:

```hcl
module "tagged_bucket" {
  source = "github.com/Viprasol-Tech/terraform-module"

  name               = "my-app-assets"
  environment        = "prod"
  owner              = "data-platform"
  versioning_enabled = true
  sse_algorithm      = "AES256"

  tags = {
    CostCenter = "1234"
    Project    = "billing"
  }
}

output "bucket_arn" {
  value = module.tagged_bucket.bucket_arn
}
```

With customer-managed KMS encryption:

```hcl
module "tagged_bucket" {
  source = "github.com/Viprasol-Tech/terraform-module"

  name          = "my-secure-data"
  environment   = "prod"
  sse_algorithm = "aws:kms"
  kms_key_arn   = "arn:aws:kms:us-east-1:111122223333:key/abcd-1234"
}
```

## Inputs

| Name                  | Description                                                                 | Type          | Default       | Required |
| --------------------- | --------------------------------------------------------------------------- | ------------- | ------------- | :------: |
| `name`                | Base name used to derive the bucket name (S3 naming rules apply).            | `string`      | n/a           |   yes    |
| `environment`         | Deployment environment; tagged and appended to the bucket name.             | `string`      | `"dev"`       |    no    |
| `owner`               | Team or individual responsible; applied as the `Owner` tag.                 | `string`      | `"platform"`  |    no    |
| `force_destroy`       | Allow destroying a non-empty bucket. Use with caution.                      | `bool`        | `false`       |    no    |
| `versioning_enabled`  | Enable object versioning on the bucket.                                     | `bool`        | `true`        |    no    |
| `sse_algorithm`       | Server-side encryption algorithm: `AES256` or `aws:kms`.                    | `string`      | `"AES256"`    |    no    |
| `kms_key_arn`         | KMS key ARN used when `sse_algorithm = "aws:kms"`.                          | `string`      | `null`        |    no    |
| `block_public_access` | Enable all four S3 public-access-block settings.                            | `bool`        | `true`        |    no    |
| `tags`                | Extra tags merged onto the module's standard tags.                          | `map(string)` | `{}`          |    no    |

### Validation rules

- `name` — 3–63 chars, lowercase alphanumeric or hyphens, must start and end alphanumeric.
- `environment` — one of `dev`, `staging`, `prod`.
- `sse_algorithm` — one of `AES256`, `aws:kms`.

## Outputs

| Name                          | Description                                              |
| ----------------------------- | ------------------------------------------------------- |
| `bucket_id`                   | The name (ID) of the S3 bucket.                         |
| `bucket_arn`                  | The ARN of the S3 bucket.                               |
| `bucket_domain_name`          | The global domain name of the bucket.                   |
| `bucket_regional_domain_name` | The region-specific domain name of the bucket.          |
| `bucket_region`               | The AWS region the bucket resides in.                   |
| `versioning_status`           | The configured versioning status (`Enabled`/`Suspended`). |
| `tags`                        | The full resolved set of tags applied to the bucket.    |

## Contributing

Contributions are welcome. Please open an issue to discuss substantial changes first, then submit a pull request. Keep HCL formatted with `terraform fmt`, validated with `terraform validate`, and add or update the example when changing the input/output surface.

## Disclaimer

This module is provided for educational and reference purposes. Provisioning cloud infrastructure incurs real costs and can affect production systems. Always run `terraform plan` and review changes before `apply`. You are responsible for the resources created in your own AWS account.

## Contact — Viprasol Tech Private Limited

- Website: [viprasol.com](https://viprasol.com)
- Email: [support@viprasol.com](mailto:support@viprasol.com)
- Telegram: [t.me/viprasol_help](https://t.me/viprasol_help) | WhatsApp: +91 96336 52112
- GitHub: [@Viprasol-Tech](https://github.com/Viprasol-Tech) | [LinkedIn](https://www.linkedin.com/in/viprasol/) | X [@viprasol](https://twitter.com/viprasol)

## License

[MIT](LICENSE) (c) 2025 Viprasol Tech Private Limited
