variable "name_prefix" {
  type = string
}

variable "dynamodb_table_name" {
  type = string

}

variable "bucket_name" {
  type = string
}

variable "store_policy" {
  type = any
}

variable "tags" {
  type = map(string)
}
