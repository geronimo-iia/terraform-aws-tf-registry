data "aws_api_gateway_resource" "root" {
  rest_api_id = var.rest_api_id
  path        = "/"
}

resource "aws_api_gateway_resource" "providers_root" {
  rest_api_id = data.aws_api_gateway_resource.root.rest_api_id
  parent_id   = data.aws_api_gateway_resource.root.id
  path_part   = "providers.v1"
}


resource "aws_api_gateway_resource" "namespace" {
  rest_api_id = aws_api_gateway_resource.providers_root.rest_api_id
  parent_id   = aws_api_gateway_resource.providers_root.id
  path_part   = "{namespace}"
}

resource "aws_api_gateway_resource" "type" {
  rest_api_id = aws_api_gateway_resource.namespace.rest_api_id
  parent_id   = aws_api_gateway_resource.namespace.id
  path_part   = "{type}"
}

resource "aws_api_gateway_resource" "versions" {
  rest_api_id = aws_api_gateway_resource.type.rest_api_id
  parent_id   = aws_api_gateway_resource.type.id
  path_part   = "versions"
}