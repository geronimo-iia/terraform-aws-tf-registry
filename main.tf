
module "jwt" {
  source          = "./modules/registry-jwt"
  secret_key_name = var.secret_key_name != null ? var.secret_key_name : "${var.name_prefix}-jwt"
  kms_key_id      = var.kms_key_id
  tags            = var.tags

}

module "store" {
  source                        = "./modules/registry-store"
  name_prefix                   = var.name_prefix
  storage                       = var.storage
  tags                          = var.tags
  public_access                 = var.s3_public_access
  enable_point_in_time_recovery = var.dynamodb_enable_point_in_time_recovery
}

module "authorizer" {
  source          = "./modules/registry-authorizer"
  name_prefix     = var.name_prefix
  tags            = var.tags
  secret_key_name = module.jwt.name
  secret_key_arn  = module.jwt.arn

  depends_on = [
    module.jwt
  ]
}

module "download" {
  source      = "./modules/registry-download"
  name_prefix = var.name_prefix
  tags        = var.tags

  store_policy        = module.store.store_policy
  dynamodb_table_name = module.store.dynamodb_table_name
  bucket_name         = module.store.bucket_name
}

module "registry" {
  source = "./modules/registry-service"

  name_prefix            = var.name_prefix
  friendly_hostname      = var.friendly_hostname
  api_type               = var.api_type
  api_access_policy      = var.api_access_policy
  domain_security_policy = var.domain_security_policy
  vpc_endpoint_ids       = var.vpc_endpoint_ids
  tags                   = var.tags

  lambda_authorizer_name = module.authorizer.function_name
  lambda_download_name   = module.download.name

  store_policy        = module.store.store_policy
  dynamodb_table_name = module.store.dynamodb_table_name

  depends_on = [
    module.authorizer
  ]
}

resource "null_resource" "apigateway_create_deployment" {
  depends_on = [
    module.registry
  ]
  provisioner "local-exec" {
    command     = "aws apigateway create-deployment --rest-api-id ${module.registry.rest_api_id} --stage-name ${module.registry.rest_api_stage_name}"
    interpreter = ["/bin/bash", "-c"]
  }
}
