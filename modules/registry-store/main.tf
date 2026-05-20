locals {
  default_name        = "${var.name_prefix}-modules"
  dynamodb_table_name = var.storage.dynamodb.name != null ? var.storage.dynamodb.name : local.default_name
  bucket_name         = var.storage.bucket.name != null ? var.storage.bucket.name : local.default_name
}

resource "aws_dynamodb_table" "modules" {
  #checkov:skip=CKV2_AWS_16:Auto-scaling not needed with PAY_PER_REQUEST billing
  #checkov:skip=CKV_AWS_119:Using default aws/dynamodb encryption - CMK not required
  name = local.dynamodb_table_name

  hash_key  = "Id"
  range_key = "Version"

  billing_mode   = var.storage.dynamodb.billing_mode
  read_capacity  = var.storage.dynamodb.billing_mode == "PAY_PER_REQUEST" ? null : var.storage.dynamodb.read
  write_capacity = var.storage.dynamodb.billing_mode == "PAY_PER_REQUEST" ? null : var.storage.dynamodb.write

  # Id is the full namespace/name/provider string used to identify a particular module.
  attribute {
    name = "Id"
    type = "S"
  }

  # Version is a normalized semver-style version number, like 1.0.0.
  attribute {
    name = "Version"
    type = "S"
  }
  server_side_encryption { # default alias/aws/dynamodb
    enabled = true
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  tags = merge(var.tags, { Name : local.dynamodb_table_name })
}


resource "aws_s3_bucket" "bucket" {
  #checkov:skip=CKV_AWS_18:Access logging handled at org level via CloudTrail
  #checkov:skip=CKV_AWS_144:Cross-region replication not needed for registry modules
  #checkov:skip=CKV_AWS_145:Using SSE-S3 (AES256) - KMS not required for module artifacts
  #checkov:skip=CKV2_AWS_61:Lifecycle policy not needed - module versions are kept indefinitely
  #checkov:skip=CKV2_AWS_62:Event notifications not required
  bucket        = local.bucket_name
  force_destroy = false
  tags          = merge(var.tags, { Name : local.bucket_name })
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  #checkov:skip=CKV2_AWS_65:Using BucketOwnerPreferred for legacy ACL compatibility
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.bucket]
  bucket     = aws_s3_bucket.bucket.id
  acl        = "private"
}

resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = var.public_access.block_public_acls
  ignore_public_acls      = var.public_access.ignore_public_acls
  block_public_policy     = var.public_access.block_public_policy
  restrict_public_buckets = var.public_access.restrict_public_buckets
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}