locals {

  api_access_policy = var.api_type != "PRIVATE" ? var.api_access_policy : ""
  service_base_url = (
    local.friendly_hostname_base_url != "" ? local.friendly_hostname_base_url : aws_api_gateway_deployment.live.invoke_url
  )

  hostname_enabled = var.friendly_hostname != null

  friendly_hostname          = local.hostname_enabled ? var.friendly_hostname : { host = "", acm_certificate_arn = "" }
  friendly_hostname_base_url = local.hostname_enabled ? "https://${local.friendly_hostname.host}" : ""
}


data "aws_lambda_function" "auth" {
  function_name = var.lambda_authorizer_name
}

data "aws_lambda_function" "download" {
  function_name = var.lambda_download_name
}

