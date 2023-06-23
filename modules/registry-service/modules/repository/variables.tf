variable "rest_api_id" {
  type        = string
  description = "The id of the API Gateway REST API that contains the given parent_resource_id."
}

variable "module_bucket_name" {
  type        = string
  default     = null
  description = "module bucket name"
}

variable "credentials_role_arn" {
  type        = string
  description = "The ARN of the IAM role to use when querying the DynamoDB table given in dynamodb_table_name. This role must have at least full read-only access to the table contents."
}
