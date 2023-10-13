variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}


variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}


variable "lambda_authorizer_name" {
  description = "lambda authorizer name "
  type        = string
}

variable "lambda_download_name" {
  description = "lambda download name"
  type        = string
}

variable "friendly_hostname" {
  type = object({
    host                = string
    acm_certificate_arn = string
  })
}

variable "api_type" {
  type = list(string)
}

variable "api_access_policy" {
  type = string
}

variable "domain_security_policy" {
  type = string
}

variable "vpc_endpoint_ids" {
  type = list(string)
}

variable "dynamodb_table_name" {
  type = string

}

variable "store_policy" {
  type = any
}

