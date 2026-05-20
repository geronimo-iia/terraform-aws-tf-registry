# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.3.0 Unreleased]

### Added

- Step-by-step guide for deploy, configure, release, and pull workflow (`example/registry/readme.md`)
- Example dummy module for testing (`example/my-module/`)
- `.env.sample` for registry example configuration

### Removed

- `null_resource` for API Gateway redeployment (redundant — child module already handles it)
- `null` provider dependency
- `timestamp()`-based forced redeployment on every apply

### Changed

- API Gateway deployment now uses content-based `triggers` (hash of authorizer, integrations, modules) — only redeploys when the API structure actually changes
- Centralize provider version constraints in root `versions.tf` (remove from child modules)
- Add `hashicorp/external` and `hashicorp/random` providers to root module
- Replace global `checkov.yaml` skip list with inline suppressions on each resource
- Update `.tool-versions` to latest (terraform 1.15.3, terragrunt 1.0.5, checkov 3.2.529)
- Simplify CI scan workflow (use `setup-python` + pip instead of asdf)
- Pin Python 3.12.11 and checkov 3.2.529 in CI
- Add dependabot for GitHub Actions and pip (PyJWT)
- Align example provider versions with root module
- Replace deprecated `managed_policy_arns` and `inline_policy` with dedicated resources
- Replace deprecated `stage_name` on `aws_api_gateway_deployment` with `aws_api_gateway_stage`
- Add API Gateway access logging with 7-day retention
- Add API Gateway method settings with ERROR-level execution logging
- Fix terragrunt examples for v1 compatibility

### Fixed

- Update provider version constraints (widen `aws ~> 5.90`, `archive ~> 2.8`, `null ~> 3.2`)
- Remove redundant version declarations in child modules
- Update Python lambda runtime to 3.12
- Pin PyJWT version in requirements.txt (`>=2.8,<3`)
- Set `reserved_concurrent_executions` to 100 to prevent runaway costs
- Remove tfsec (deprecated, replaced by checkov)
- Update CI workflow (ASDF installation, action versions)
- Add `force_destroy = false` on S3 bucket to prevent accidental deletion
- Remove unused import in authorizer lambda

## [1.2.2]

### Added

- Default encryption on S3 bucket (SSE-S3) and DynamoDB table
- DynamoDB point-in-time recovery
- Checkov and tfsec security scans

### Fixed

- Public ACL on S3 bucket
- API Gateway invoke download URL permissions

## [1.1.1]

### Fixed

- Archive path for lambda authorizer
- AWS provider version constraint
- Remove constant statement id "AllowExecutionFromAPIGateway"

## [1.1.0]

### Added

- `X-Terraform-Get` header support for download API
- Dedicated lambda integration for download API with S3 presigned URLs

### Changed

- Refactor IAM policy declarations
- Create shared common policy from storage module
- Simplify local variable usage
- Authorizer is no longer optional
- Propagate tags on roles and resources
- Use terraform `name_prefix` for resources

### Removed

- Unused code

## [1.0.2]

### Fixed

- Documentation fix for registry.terraform.io

## [1.0.1]

### Added

- Integration to https://registry.terraform.io/modules/geronimo-iia/tf-registry/aws/latest

### Fixed

- Documentation update

## [1.0.0]

### Added

- JWT secret initialization via AWS Secrets Manager
- Lambda authorizer for API Gateway authentication
- Automated API Gateway redeployment
- Dedicated S3 bucket storage for module artifacts
- Python script to deploy terraform modules
- DynamoDB capacity management (provisioned / pay-per-request)
- Tags on all resources
- Custom naming for DynamoDB table and S3 bucket
- Storage outputs (bucket name/arn, table name/arn)
- Architecture overview documentation
- Usage example

### Changed

- Group all modules.v1 API resources inside dedicated module
- Extract registry-store module from registry-service
- Keep default variable values at root module level

### Fixed

- Remove deprecated template provider
- Fix error in default settings
