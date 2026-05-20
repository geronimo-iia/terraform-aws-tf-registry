# Terraform Private Registry — Step-by-Step Guide

## 1. Deploy the registry

Apply the Terraform module to provision the registry infrastructure (API Gateway, Lambda, DynamoDB, S3, Secrets Manager):

```hcl
module "registry" {
  source      = "../..//"
  name_prefix = "registry"

  storage = {
    dynamodb = { name = "my-domain-registry-tfe" }
    bucket   = { name = "my-domain-registry-tfe" }
  }

  friendly_hostname = {
    host                = "registry.my-domain.com"
    acm_certificate_arn = aws_acm_certificate.certificate.arn
  }
}
```

After apply, note the outputs:

- `registry_secret_key_name` — Secrets Manager key for JWT signing
- `dynamodb_table_name` — DynamoDB table storing module metadata
- `bucket_name` — S3 bucket storing module archives
- `dns_alias` — DNS record to point your domain at


## 2. Install and configure `tfr`

```bash
uv tool install aws_terraform_registry
```

Create a `.env` file in your working directory (or set environment variables):

```env
TFR_SECRET_KEY_NAME="<registry_secret_key_name output>"
TFR_REPOSITORY_URL="https://registry.my-domain.com"
TFR_DYNAMODB_TABLE_NAME="<dynamodb_table_name output>"
TFR_BUCKET_NAME="<bucket_name output>"
TFR_DEFAULT_NAMESPACE=my-namespace
```

Verify:

```bash
tfr config
```


## 3. Generate a token

```bash
AWS_REGION=eu-west-1 tfr generate-token --weeks 52
```

This retrieves the JWT secret from Secrets Manager and produces a signed token valid for 52 weeks.


## 4. Configure Terraform credentials

Add the token to `~/.terraformrc`:

```hcl
credentials "registry.my-domain.com" {
  token = "<token from step 3>"
}
```

Or generate it automatically:

```bash
AWS_REGION=eu-west-1 tfr generate-terraformrc --output-directory ~/ --weeks 52
```


## 5. Release a module

Prepare your module as a `.tar.gz` archive (Terraform expects gzip, not zip):

```bash
cd ./example
tar -czf my-module.tar.gz -C my-module .
```

Release it to the registry:

```bash
AWS_REGION=eu-west-1 tfr release \
  --namespace my-namespace \
  --name my-module \
  --system aws \
  --version 1.0.0 \
  --source ./my-module.tar.gz
```

This uploads the archive to S3 and registers the module in DynamoDB with an S3 signed URL as source.


## 6. Use the module in Terraform

with `example/registry/test.tf`
```hcl
module "example" {
  source  = "registry.my-domain.com/my-namespace/my-module/aws"
  version = "1.0.0"
}
```

Then:

```bash
terraform init
```

Terraform will:
1. Query the registry API for the module download URL
2. Authenticate using the token from `.terraformrc`
3. Download the `.tar.gz` from S3 via a pre-signed URL


## Notes

- **Archive format**: always use `.tar.gz` — Terraform's module getter expects gzip, not zip.
- **`publish` vs `release`**: use `release` to store archives in the registry bucket (with signed URL access). `publish` only registers an external URL without uploading.
- **Unpublish**: `tfr unpublish --namespace X --name Y --system Z --version V` removes the DynamoDB entry (S3 archive is kept).
