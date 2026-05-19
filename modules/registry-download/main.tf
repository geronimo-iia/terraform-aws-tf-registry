locals {
  function_name = "${var.name_prefix}-download"
}


# --------------------------------------------------------
# Lambda Role
# --------------------------------------------------------

resource "aws_iam_role" "download" {
  name_prefix        = local.function_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "download_basic_execution" {
  role       = aws_iam_role.download.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "download" {
  name   = "download"
  role   = aws_iam_role.download.id
  policy = var.store_policy
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}


# --------------------------------------------------------
# Lambda Archive
# --------------------------------------------------------


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/main.py"
  output_path = "lambda_function.zip"
}


# --------------------------------------------------------
# Lambda
# --------------------------------------------------------
resource "aws_lambda_function" "download" {
  #checkov:skip=CKV_AWS_50:X-Ray tracing not needed for simple download lambda
  #checkov:skip=CKV_AWS_117:VPC not required - accesses DynamoDB and S3 via public endpoints
  #checkov:skip=CKV_AWS_116:DLQ not applicable for synchronous API-triggered lambda
  #checkov:skip=CKV_AWS_173:Environment variables contain only resource names, not secrets
  #checkov:skip=CKV_AWS_272:Code signing not required for internal lambda
  function_name    = local.function_name
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role        = aws_iam_role.download.arn
  runtime     = "python3.12"
  handler     = "main.lambda_handler"
  timeout     = 10
  memory_size = 128
  # kms_key_arn =  AWS Lambda uses a default service key
  reserved_concurrent_executions = 100
  tags                           = merge(var.tags, { Name : local.function_name })
  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
      TABLE_NAME  = var.dynamodb_table_name
    }
  }
}
