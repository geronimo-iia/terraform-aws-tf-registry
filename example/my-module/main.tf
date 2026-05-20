variable "name" {
  type    = string
  default = "world"
}

output "greeting" {
  value = "Hello, ${var.name}!"
}
