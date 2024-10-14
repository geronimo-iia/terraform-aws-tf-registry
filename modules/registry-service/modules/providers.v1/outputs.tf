

output "rest_api_id" {
  value = aws_api_gateway_resource.providers_root.id
}


output "rest_api_path" {
  value = aws_api_gateway_resource.providers_root.path
}
