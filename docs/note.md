# Notes

## Testing a blob api to download module using JWT token:

With terraform blob module (see `docs/blob`), we had added an api entry point to create a proxy on dedicated bucket [like this example[(https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html#API_GetObject_Examples|).

With blob api authentication, we had to configure a [netrc file](https://everything.curl.dev/usingcurl/netrc).
With a netrc like this:
```txt
machine registry.my-domain.com
login Bearer
password My_JWT_Tokem
```

And adding support for Basic auth in lambda authorizer, things "work"....
But, we add to configure `.terraformrc` for registry API and a `.netrc` for module download from registry...

Rather than use API gateway as a s3 proxy, we prefer using s3 presigned url in the "download response".


## Assume role and terraform trouble with `aws-mfa`

If you have an iam user with aws key configured to use with your terraform provider, you will not facing any issue.

Most often, we use multiple assume role in order to manage multiple aws account for the same entreprise.
And most often it works very well :)

But (...) I faced an issue with the python module 'aws-mfa' recently, that i wanna share. If you known what's wrong, let me known :)

With a configuration like this:

```text
[profile myorg-shared-mfa-long-term]
region=eu-west-1
output=json

[profile myorg-shared-mfa]
region=eu-west-1
output=json

[profile myorg-prod-admin]
region=eu-west-1
role_arn = arn:aws:iam::123456789:role/myorg-admin
source_profile = myorg-shared-mfa

```

and credential like this:

```text
[profile myorg-shared-mfa-long-term] # here we store our iam user key
aws_access_key_id = AAAAAA
aws_secret_access_key = BBBBBBB
aws_mfa_device = arn:aws:iam::0000000:mfa/contact@myorg.com

[myorg-shared-mfa]
aws_mfa_device = arn:aws:iam::0000000:mfa/contact@myorg.com
aws_access_key_id = 
aws_secret_access_key = 

```

If you do this for your `terraform init`, it will failed with a `NoCredentialProviders: no valid providers in chain`:

```bash
aws-mfa --profile myorg-shared-mfa --force 
export AWS_PROFILE="myorg-prod-admin"
```

BUT, with this, `terraform init` will be happy :

```bash
aws-mfa --profile myorg-shared-mfa --force --assume-role arn:aws:iam::123456789:role/myorg-admin
export AWS_PROFILE="myorg-shared-mfa"
```

Strange isn't it ? 
As an '--assume-role' option preconfigure all environment variables, "maybe" terraform probably fail to read all runtime information of a client session on 'myorg-shared-mfa'.

## few bash command line for testing

```bash
curl https://registry-my-domain.com/.well-known/terraform.json
> {"modules.v1":"/modules.v1/"}
```

```bash
curl https://registry-my-domain.com/modules.v1/
> {"message":"Missing Authentication Token"}
```

```bash
curl -H 'Accept: application/json' -H "Authorization: Bearer ${JWT_TOKEN}"  https://registry-my-domain.com/modules.v1/my-org/aws/kinesis-firehose/versions
```

```bash
>>
{
    "modules": [
        {
            "versions": [
                {"version": "0.4.4"}            ]
        }
    ]
}
```

```bash
curl -H 'Accept: application/json' -H "Authorization: Bearer ${JWT_TOKEN}"  https://registry-my-domain.com/modules.v1/my-org/aws/kinesis-firehose/0.4.4/download
```

```bash
>>
{
  "version": "{S=0.4.4}",
  "source": "{S=https:\/\/github..com\/my-org\/terraform-modules\/terraform-aws-kinesis-firehose.git?ref=v1.2.0}",
}
```

Blob api access for module stored in the bucket:

```bash
curl  -H 'Accept: application/x-tar' -H "Authorization: Bearer ${JWT_TOKEN}" "https://registry-my-domain.com/blob/my-org/aws/kinesis-firehose/0.4.4/archive.tar.gz" --output archive.tar.gz
```
