# Improvement Proposals

## 1. Upgrade Lambda runtimes (Critical) Done

Both lambdas use `python3.9` which reaches end-of-support. Upgrade to `python3.12` (or at least `python3.11`):
- `modules/registry-authorizer/main.tf` → `runtime = "python3.12"`
- `modules/registry-download/main.tf` → `runtime = "python3.12"`

## 2. Loosen/update provider version constraints Done

`versions.tf` pins `aws = "~> 5.5.0"` which only allows patch updates within 5.5.x. The AWS provider is now at 5.80+. Consider widening to `~> 5.0` or at least `~> 5.5` (without the trailing `.0`) to benefit from bug fixes and new resources.

Same for `archive = "2.4.0"` and `null = "3.2.1"` — exact pins prevent any updates. Use `~> 2.4` and `~> 3.2`.

## 3. Replace `null_resource` with `terraform_data`

The `null_resource` + `local-exec` for API Gateway deployment is fragile:
- It runs on every `apply` (no real trigger logic)
- It depends on AWS CLI being available locally
- Consider using `aws_api_gateway_deployment` with proper triggers, or at minimum replace `null_resource` with the built-in `terraform_data` resource (Terraform 1.4+) and remove the `null` provider dependency entirely.

## 4. Pin PyJWT version in requirements.txt

`requirements.txt` just says `PyJWT` with no version pin. A breaking change in PyJWT could silently break the authorizer. Pin it: `PyJWT>=2.8,<3`.

## 5. Lambda security improvements DONE

- Enable X-Ray tracing on both lambdas (currently suppressed with `tfsec:ignore`). Tracing is cheap and invaluable for debugging auth/download issues.
- Set `reserved_concurrent_executions` to a reasonable limit (e.g., 100) instead of `-1` (unlimited) to prevent runaway costs from abuse.
- Consider encrypting Lambda environment variables with a CMK (`kms_key_arn`), especially for the authorizer which handles `SECRET_KEY_NAME`.

## 6. S3 bucket improvements DONE

- Add `force_destroy = false` explicitly to prevent accidental bucket deletion. DONE


## 8. Authorizer Lambda — code quality: DONE

In `authorizer.py`: 
- Remove unused import: `from curses import nonl` DONE
- The global secret cache has no thread-safety concern (Lambda is single-threaded), but the 1-hour TTL is hardcoded. Consider making it configurable via env var.

## 9. CI/CD workflow improvements

In `.github/workflows/tfsec.yml`:
- `tfsec` is deprecated — replaced by Trivy (by Aqua Security). Migrate to `aquasecurity/trivy-action`.
- `actions/checkout@v3` → upgrade to `@v4`.
- ASDF installation from git is slow; consider using a pre-built action or pinning tool versions in a more maintainable way.

## 10. Unused variable

`enable_providers` in `variables.tf` is declared but never referenced anywhere in the module. Either implement the providers API or remove the dead variable.

## 11. Add API Gateway access logging

The API Gateway has no access logging configured. Add a `aws_api_gateway_stage` with `access_log_settings` pointing to a CloudWatch log group — essential for debugging and audit.

