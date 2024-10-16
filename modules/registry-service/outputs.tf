
output "services" {
  description = "A service discovery configuration map for the deployed services. A JSON-serialized version of this should be published at /.well-known/terraform.json on an HTTPS server running at the friendly hostname for this registry."
  value = {
    # We have to do some replacement shenanigans here to ensure we don't
    # double up slashes if the root path also starts with a slash.
    "modules.v1" = replace("${local.service_base_url}//${module.modules_v1.rest_api_path}/", "/\\/\\/\\//", "/")
  }
}

output "dns_alias" {
  description = "If the friendly_hostname input variable is set, this exports the hostname and Route53 zone id that should be used to point the friendly hostname at the registry API. If not using Route53 for DNS, you can alternatively create a regular CNAME record to the returned hostname. If friendly hostname is not enabled then this output is always null."
  value = (
    local.hostname_enabled ? {
      hostname        = aws_api_gateway_domain_name.main[0].regional_domain_name
      route53_zone_id = aws_api_gateway_domain_name.main[0].regional_zone_id
    } : null
  )
}

output "rest_api_id" {
  description = "The id of the API Gateway REST API managed by this module."
  value       = aws_api_gateway_rest_api.root.id
}

output "rest_api_stage_name" {
  description = "The id of the API Gateway deployment stage managed by this module."
  value       = aws_api_gateway_deployment.live.stage_name
}
