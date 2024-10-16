# Terraform Private Registry for AWS


This Terraform module establishes a private registry for Terraform, allowing
you to publish your own modules in a location you control independent of
Terraform's public registry at [`registry.terraform.io`](https://registry.terraform.io/).

Terraform module addresses can include
an optional hostname part which allows them to be downloaded from services
other than the public registry:

```txt
module "awesomeapp" {
  source = "tf.example.com/awesomecorp/awesomeapp/aws"
}
```

This is a fork from https://github.com/apparentlymart/terraform-aws-tf-registry, created by Martin Atkins.

## Features :

### v1.0.2

- Use JWT secret creation and sharing with secret manager
- Add lambda autorizer for authentication
- automate API gateway redeployment
- Add dedicated bucket storage
- Create [python client](https://github.com/geronimo-iia/terraform-aws-tf-registry-cli) to deploy terraform module
- Tags resources
- Add dynamodb capacity management and custom naming
- Add bucket custom naming
- Usage example
- Automate API update after change


With this registy implemnentation, you can add a module source from "anywhere" like git, http server, and s3 bucket.

But for all this storage, you add to handle authentication (...).

> For my point of view, the more simple is to deploy zipped terraform module on a bucket (with ad hoc CI-CD pipeline) and handle access with aws s3 signature.
> That's why i added a dedicated bucket in this stack.

The registry return source module url like s3::https://s3....s/vpc.zip", when you use release command from  [this python client](https://github.com/geronimo-iia/terraform-aws-tf-registry-cli).

The s3:: prefix causes Terraform to use AWS-style authentication when accessing the given URL. 
No need to give public access to your bucket. [Read S3 Bucket](https://developer.hashicorp.com/terraform/language/modules/sources#s3-bucket)

> All management use case around this private terraform registry can be handled by [this python client](https://github.com/geronimo-iia/terraform-aws-tf-registry-cli)

Ths project has been battle tested in huge production workload since 2 years and cost less than 10$ per month.

## v1.1.0 

- Usage of "X-Terraform-Get" for download API
- Add a dedicated lambda integration for download API : use s3 presigned url for all module which came from registry bucket
- Add tag on each resource, rewrote some iam declaration


Note:

- Using presigned s3 url,  permit us to use this registry from other platform with no direct credentials with aws. They just see an https url.
- simplify sharing in a multi account context : we just manage JWT token



## Terraform private registry design

![Architecture](./docs/registry.png)

Reference:

- [Authorizer](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html)
- [authorizer blueprint](https://raw.githubusercontent.com/awslabs/aws-apigateway-lambda-authorizer-blueprints/master/blueprints/python/api-gateway-authorizer-python.py)
- [registry](https://github.com/bikescholl/terraform-aws-tf-registry)
- [registry original](https://github.com/apparentlymart/terraform-aws-tf-registry)


### Implementation

You could have more specific information on [original registry implementation document here](./modules/registry-service/README.md).

Terraform's documented registry HTTP API is implemented via Amazon API Gateway relaying requests to a DynamoDB table that contains a simple index of modules.
The module packages themselves can be stored at any non-registry [module source address](https://www.terraform.io/docs/modules/sources.html) supported by Terraform, including in an S3 bucket with standard AWS authentication.


### Access Control

Terraform CLI supports bearer-token authentication credentials when making API requests. Credentials are configured on a per-hostname basis and apply to all services at that hostname.

Authorization is based on JWT token.

## Usage with terraform, terragrunt

### Configuration

Users must create `.terraformrc` file in their $HOME directory, with this content:

```hcl
credentials "registry.my-domain.com" {
    token = "Mytoken"
}
```

### Usage

```txt
module "test" {
    source = "registry.my-domain/data/kinesis-firehose/aws"
    version = "0.2.0"
}
```

or

```txt
module "test" {
    source = "registry.my-domain/data/kinesis-firehose/aws"
}
```

## Roadmap

- Add a Rest API to publish module with dedicated credentials
- Add an optional way to publish an event (with AWS Event Bridge) when a new release is published
- Add a way to mark a module as deprecated ?

## Example

You could retrieve this source under [example/registry](./example/registry/main.tf)

```txt
locals {
  root_domain_name     = "my-domain.com"
  registry_domain_name = "registry.${local.root_domain_name}"
}


data "aws_route53_zone" "selected" {
  name = local.root_domain_name
}

# create ACME Certificat
resource "aws_acm_certificate" "certificate" {
  domain_name       = local.registry_domain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

# create DNS record for validate
resource "aws_route53_record" "certificate" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.certificate.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.certificate.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.certificate.domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.selected.zone_id
  ttl             = 60
}

# Validate certificat
resource "aws_acm_certificate_validation" "certificate" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [aws_route53_record.certificate.fqdn]
}




module "registry" {
  source  = "geronimo-iia/tf-registry/aws"
  version = "1.0.2"
  name_prefix = "registry"

  storage = {
    dynamodb = {
      name : "my-domain-registry-tfe"
      billing_mode : "PROVISIONED"
      read : 5
      write : 1
    }
    bucket = {
      name : "my-domain-registry-tfe"
    }
  }

  friendly_hostname = {
    host                = local.registry_domain_name
    acm_certificate_arn = aws_acm_certificate.certificate.arn
  }

  tags = {
    Product : "Registry"
    ProductComponent : "terraform"
  }

  depends_on = [aws_acm_certificate.certificate]
}


resource "aws_route53_record" "registry" {
  zone_id = data.aws_route53_zone.selected.zone_id

  name = "${local.registry_domain_name}."
  type = "A"
  alias {
    name                   = module.registry.dns_alias.hostname
    zone_id                = module.registry.dns_alias.route53_zone_id
    evaluate_target_health = true
  }

  depends_on = [module.registry]
}

```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | 2.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | 3.2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_authorizer"></a> [authorizer](#module\_authorizer) | ./modules/registry-authorizer | n/a |
| <a name="module_download"></a> [download](#module\_download) | ./modules/registry-download | n/a |
| <a name="module_jwt"></a> [jwt](#module\_jwt) | ./modules/registry-jwt | n/a |
| <a name="module_registry"></a> [registry](#module\_registry) | ./modules/registry-service | n/a |
| <a name="module_store"></a> [store](#module\_store) | ./modules/registry-store | n/a |

## Resources

| Name | Type |
|------|------|
| [null_resource.apigateway_create_deployment](https://registry.terraform.io/providers/hashicorp/null/3.2.1/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_access_policy"></a> [api\_access\_policy](#input\_api\_access\_policy) | If using a Private API requires you to have an access policy configured and accepts a string, but must be valid json. Defaults to Null | `string` | `null` | no |
| <a name="input_api_type"></a> [api\_type](#input\_api\_type) | Sets API type if you want a private API without a custom domain name, defaults to EDGE for public access | `list(string)` | <pre>[<br>  "EDGE"<br>]</pre> | no |
| <a name="input_domain_security_policy"></a> [domain\_security\_policy](#input\_domain\_security\_policy) | Sets the TLS version to desired state, defaults to 1.2 | `string` | `"TLS_1_2"` | no |
| <a name="input_dynamodb_enable_point_in_time_recovery"></a> [dynamodb\_enable\_point\_in\_time\_recovery](#input\_dynamodb\_enable\_point\_in\_time\_recovery) | Enable DynamoDB point in time recovery | `bool` | `true` | no |
| <a name="input_friendly_hostname"></a> [friendly\_hostname](#input\_friendly\_hostname) | Configures a "friendly hostname" that will be used to reference objects in this registry. If this is set, the given hostname and certificate will be registered against the created API. Can be left unset if the service discovery information will be separately published at the friendly hostname, using the "services" output value. | <pre>object({<br>    host                = string<br>    acm_certificate_arn = string<br>  })</pre> | `null` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Optional custom kms key id (default aws/secretsmanager) | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A name to use as the prefix for the created API Gateway REST API, DynamoDB tables, etc | `string` | `"terraform-registry"` | no |
| <a name="input_s3_public_access"></a> [s3\_public\_access](#input\_s3\_public\_access) | Bucket Public Access Block | <pre>object({<br>    block_public_acls       = bool,<br>    ignore_public_acls      = bool,<br>    block_public_policy     = bool,<br>    restrict_public_buckets = bool<br>  })</pre> | <pre>{<br>  "block_public_acls": true,<br>  "block_public_policy": true,<br>  "ignore_public_acls": true,<br>  "restrict_public_buckets": true<br>}</pre> | no |
| <a name="input_secret_key_name"></a> [secret\_key\_name](#input\_secret\_key\_name) | Optional AWS Secret name to store JWT secret | `string` | `null` | no |
| <a name="input_storage"></a> [storage](#input\_storage) | n/a | <pre>object({<br>    dynamodb = object({<br>      name         = optional(string, null)<br>      billing_mode = optional(string, "PAY_PER_REQUEST")<br>      read         = optional(number, 1)<br>      write        = optional(number, 1)<br>    })<br>    bucket = object({<br>      name = optional(string, null)<br>    })<br>  })</pre> | <pre>{<br>  "bucket": {<br>    "name": null<br>  },<br>  "dynamodb": {<br>    "billing_mode": "PAY_PER_REQUEST",<br>    "name": null,<br>    "read": 1,<br>    "write": 1<br>  }<br>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Resource tags | `map(string)` | `{}` | no |
| <a name="input_vpc_endpoint_ids"></a> [vpc\_endpoint\_ids](#input\_vpc\_endpoint\_ids) | Sets the VPC endpoint ID for a private API, defaults to null | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | Bucket arn |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Bucket name |
| <a name="output_dns_alias"></a> [dns\_alias](#output\_dns\_alias) | If the friendly\_hostname input variable is set, this exports the hostname and Route53 zone id that should be used to point the friendly hostname at the registry API. If not using Route53 for DNS, you can alternatively create a regular CNAME record to the returned hostname. If friendly hostname is not enabled then this output is always null. |
| <a name="output_dynamodb_table_arn"></a> [dynamodb\_table\_arn](#output\_dynamodb\_table\_arn) | Dynamodb table arn |
| <a name="output_dynamodb_table_name"></a> [dynamodb\_table\_name](#output\_dynamodb\_table\_name) | Dynamodb table name |
| <a name="output_registry_secret_key_name"></a> [registry\_secret\_key\_name](#output\_registry\_secret\_key\_name) | JWT secret key name in aws secret manager |
| <a name="output_rest_api_id"></a> [rest\_api\_id](#output\_rest\_api\_id) | The id of the API Gateway REST API managed by this module. |
| <a name="output_rest_api_stage_name"></a> [rest\_api\_stage\_name](#output\_rest\_api\_stage\_name) | The id of the API Gateway deployment stage managed by this module. |
| <a name="output_services"></a> [services](#output\_services) | A service discovery configuration map for the deployed services. A JSON-serialized version of this should be published at /.well-known/terraform.json on an HTTPS server running at the friendly hostname for this registry. |
<!-- END_TF_DOCS -->


## Notes

If you wanna use this project in production (like me...), I thinks that you should follow this tricks:

1. Fork this project into your entrprise git server and add a remote branch 'github' to this repository
2. Adjust variable of example 'registry' to deploy it in a quick and not so dirty mode :)
3. Publish a dummy terraform module, see how it's managed in the dynamodb, test a `terraform init` etc...
   Use [this python client](https://github.com/geronimo-iia/terraform-aws-tf-registry-cli).
4. Integrate the python client into your ci
5. Have a look on [notes](https://github.com/geronimo-iia/terraform-aws-tf-registry/blob/main/docs/note.md)

