variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}


variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}

variable "storage" {
  description = "Storage configuration"
  type = object({
    dynamodb = object({
      name         = optional(string, null)
      billing_mode = optional(string, "PAY_PER_REQUEST")
      read         = optional(number, 1)
      write        = optional(number, 1)
    })
    bucket = object({
      name = optional(string, null)
    })
  })
}

variable "public_access" {
  description = "Bucket Public Access Block"
  type = object({
    block_public_acls       = bool,
    ignore_public_acls      = bool,
    block_public_policy     = bool,
    restrict_public_buckets = bool
  })
  default = {
    block_public_acls : true
    ignore_public_acls : true
    block_public_policy : true
    restrict_public_buckets : true
  }
}

variable "enable_point_in_time_recovery" {
  type        = bool
  default     = true
  description = "Enable DynamoDB point in time recovery"
}