resource "aws_api_gateway_method" "download_GET" {
  rest_api_id = aws_api_gateway_resource.download.rest_api_id
  resource_id = aws_api_gateway_resource.download.id
  http_method = "GET"

  authorization = local.authorizer.mode
  authorizer_id = local.authorizer.id
}


resource "aws_api_gateway_integration" "download_GET" {
  rest_api_id             = aws_api_gateway_method.download_GET.rest_api_id
  resource_id             = aws_api_gateway_method.download_GET.resource_id
  http_method             = aws_api_gateway_method.download_GET.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_download_invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda_download" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_download_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${local.region_name}:${local.account_id}:${ var.rest_api_id}/*/${aws_api_gateway_method.download_GET.http_method}${aws_api_gateway_resource.download.path}"
}