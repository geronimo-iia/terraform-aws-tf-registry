locals {
  function_name = "${var.name_prefix}-download"
}


# --------------------------------------------------------
# Lambda Role
# --------------------------------------------------------

resource "aws_iam_role" "download" {
  name_prefix        = local.function_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
  inline_policy {
    name   = "download"
    policy = var.store_policy
  }
  tags = var.tags
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
  function_name    = local.function_name
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role        = aws_iam_role.download.arn
  runtime     = "python3.9"
  handler     = "main.lambda_handler"
  timeout     = 10
  memory_size = 128
  tags        = merge(var.tags, { Name : local.function_name })
  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
      TABLE_NAME  = var.dynamodb_table_name
    }
  }
}
