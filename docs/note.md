# Operational Notes

## Testing the registry API

### Service discovery

```bash
curl https://registry.example.com/.well-known/terraform.json
# {"modules.v1":"/modules.v1/"}
```

### Unauthenticated request (should fail)

```bash
curl https://registry.example.com/modules.v1/
# {"message":"Missing Authentication Token"}
```

### List module versions

```bash
curl -H 'Accept: application/json' \
     -H "Authorization: Bearer ${JWT_TOKEN}" \
     https://registry.example.com/modules.v1/my-org/kinesis-firehose/aws/versions
```

Response:

```json
{
  "modules": [
    {
      "versions": [
        {"version": "0.4.4"}
      ]
    }
  ]
}
```

### Download a module version

```bash
curl -H 'Accept: application/json' \
     -H "Authorization: Bearer ${JWT_TOKEN}" \
     https://registry.example.com/modules.v1/my-org/kinesis-firehose/aws/0.4.4/download
```

The response includes an `X-Terraform-Get` header with a presigned S3 URL (for modules stored in the registry bucket) or the original source URL.


## Design decision: presigned URLs vs blob proxy

An earlier iteration added an API Gateway proxy to S3 (see `docs/blob/`) that required `.netrc` configuration for authentication:

```txt
machine registry.example.com
login Bearer
password <jwt-token>
```

This meant users needed both `.terraformrc` (for registry API) and `.netrc` (for module download) — too much friction.

The current approach uses S3 presigned URLs in the download response instead. Benefits:
- Single auth mechanism (JWT via `.terraformrc` only)
- Works cross-platform without AWS credentials on the client
- Simplifies multi-account sharing


## Assume role and Terraform with aws-mfa

> **Note:** This issue is specific to the [aws-mfa](https://github.com/broamski/aws-mfa) tool. If you use AWS SSO / Identity Center, this doesn't apply.

With a profile chain like:

```ini
# ~/.aws/config
[profile myorg-shared-mfa]
region = eu-west-1

[profile myorg-prod-admin]
region = eu-west-1
role_arn = arn:aws:iam::<account-id>:role/myorg-admin
source_profile = myorg-shared-mfa
```

This **fails** with `NoCredentialProviders: no valid providers in chain`:

```bash
aws-mfa --profile myorg-shared-mfa --force
export AWS_PROFILE="myorg-prod-admin"
terraform init
```

This **works**:

```bash
aws-mfa --profile myorg-shared-mfa --force \
  --assume-role arn:aws:iam::<account-id>:role/myorg-admin
export AWS_PROFILE="myorg-shared-mfa"
terraform init
```

The `--assume-role` flag pre-populates temporary credentials directly in the profile, bypassing Terraform's inability to resolve the chained `source_profile` from aws-mfa's session tokens.
