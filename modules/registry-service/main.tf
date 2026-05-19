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
  variables = {
    deployment_version = formatdate("MMDDYYYYHHmmss", timestamp())
    version_scheme     = "MMDDYYYHHmmss"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "live" {
  #checkov:skip=CKV_AWS_120:Caching not cost-effective for low-traffic registry
  #checkov:skip=CKV_AWS_73:X-Ray tracing not needed for low-traffic registry
  #checkov:skip=CKV2_AWS_4:Metrics not needed - access logging is sufficient for observability
  #checkov:skip=CKV2_AWS_51:Client certificate not applicable - backends are Lambda and DynamoDB
  #checkov:skip=CKV2_AWS_29:WAF not required - JWT auth and concurrency limits provide protection
  deployment_id = aws_api_gateway_deployment.live.id
  rest_api_id   = aws_api_gateway_rest_api.root.id
  stage_name    = "live"
  tags          = var.tags

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_access" {
  #checkov:skip=CKV_AWS_338:7-day retention is sufficient for API access logs
  #checkov:skip=CKV_AWS_158:KMS encryption not required for access logs
  name              = "/aws/apigateway/${var.name_prefix}/access-logs"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_api_gateway_method_settings" "all" {
  #checkov:skip=CKV_AWS_225:Caching not cost-effective for low-traffic registry
  #checkov:skip=CKV2_AWS_4:Metrics not needed - access logging is sufficient for observability
  rest_api_id = aws_api_gateway_rest_api.root.id
  stage_name  = aws_api_gateway_stage.live.stage_name
  method_path = "*/*"

  settings {
    logging_level = "ERROR"
  }
}
