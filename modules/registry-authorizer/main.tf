
locals {
  function_name = "${var.name_prefix}-authorizer"
}


# --------------------------------------------------------
# Lambda Archive
# --------------------------------------------------------

data "external" "lambda_archive" {
  program = ["python", "${path.module}/scripts/build_lambda.py"]
  query = {
    src_dir              = "${path.module}/authorizer"
    output_path          = "${path.module}/authorizer_package.zip"
    install_dependencies = true
  }
}

# --------------------------------------------------------
# Lambda
# --------------------------------------------------------

resource "aws_lambda_function" "authorizer" {
  #checkov:skip=CKV_AWS_50:X-Ray tracing not needed for simple auth lambda
  #checkov:skip=CKV_AWS_117:VPC not required - only accesses Secrets Manager
  #checkov:skip=CKV_AWS_116:DLQ not applicable for synchronous authorizer
  #checkov:skip=CKV_AWS_173:Environment variables contain only a secret name reference, not the secret itself
  #checkov:skip=CKV_AWS_272:Code signing not required for internal lambda
  function_name    = local.function_name
  filename         = data.external.lambda_archive.result.archive
  source_code_hash = data.external.lambda_archive.result.base64sha256

  role        = aws_iam_role.authorizer.arn
  runtime     = "python3.12"
  handler     = "authorizer.lambda_handler"
  timeout     = 10
  memory_size = 128
  # kms_key_arn =  AWS Lambda uses a default service key
  reserved_concurrent_executions = 100
  tags                           = merge(var.tags, { Name : local.function_name })
  environment {
    variables = {
      SECRET_KEY_NAME = var.secret_key_name
    }
  }
}

# --------------------------------------------------------
# Lambda Role
# --------------------------------------------------------

resource "aws_iam_role" "authorizer" {
  name_prefix        = local.function_name
  assume_role_policy = data.aws_iam_policy_document.authorizer_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "authorizer_basic_execution" {
  role       = aws_iam_role.authorizer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "authorizer" {
  name   = "authorizer"
  role   = aws_iam_role.authorizer.id
  policy = data.aws_iam_policy_document.authorizer.json
}

data "aws_iam_policy_document" "authorizer" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:Describe*",
      "secretsmanager:Get*",
      "secretsmanager:List*",
    ]
    resources = [var.secret_key_arn]
  }
}

data "aws_iam_policy_document" "authorizer_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}



