resource "aws_api_gateway_rest_api" "root" {
  name = var.name_prefix
  endpoint_configuration {
    types            = var.api_type
    vpc_endpoint_ids = var.vpc_endpoint_ids
  }
  policy = local.api_access_policy
  tags   = merge(var.tags, { Name : var.name_prefix })

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_api_gateway_authorizer" "main" {

  rest_api_id = aws_api_gateway_rest_api.root.id
  name        = "custom"

  type                   = "TOKEN"
  authorizer_uri         = data.aws_lambda_function.auth.invoke_arn
  authorizer_credentials = aws_iam_role.auth.arn
  identity_source        = "method.request.header.Authorization"

  depends_on = [aws_iam_role.auth]
}

module "modules_v1" {
  source = "./modules/modules.v1"

  rest_api_id          = aws_api_gateway_rest_api.root.id
  dynamodb_table_name  = var.dynamodb_table_name
  credentials_role_arn = aws_iam_role.modules.arn
  custom_authorizer_id = aws_api_gateway_authorizer.main.id

  lambda_download_name       = data.aws_lambda_function.download.function_name
  lambda_download_invoke_arn = data.aws_lambda_function.download.invoke_arn
}

# hostname/.well-known/terraform.json.
module "disco" {
  source = "./modules/disco"

  rest_api_id = aws_api_gateway_rest_api.root.id
  services = {
    "modules.v1" = "${module.modules_v1.rest_api_path}/",
  }
}

resource "aws_api_gateway_deployment" "live" {
  depends_on = [
    module.modules_v1,
    module.disco,
  ]
  rest_api_id = aws_api_gateway_rest_api.root.id
  stage_name  = "live"
  variables = {
    deployment_version = formatdate("MMDDYYYYHHmmss", timestamp())
    version_scheme     = "MMDDYYYHHmmss"
  }
  lifecycle {
    create_before_destroy = true
  }
}
