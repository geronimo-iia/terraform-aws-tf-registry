
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "modules" {
  name               = "${local.name_prefix}-modules"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  inline_policy {
    name   = "store"
    policy = data.aws_iam_policy_document.modules_inline_policy.json
  }
}


data "aws_iam_policy_document" "modules_inline_policy" {
  statement {
    actions = ["dynamodb:Query",
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:GetRecords",
    "dynamodb:Scan"]
    resources = [var.dynamodb_table_arn]
  }

  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
    ]
    resources = [var.bucket_arn,
    "${var.bucket_arn}/*"]
  }
}

resource "aws_iam_role" "auth" {
  count = length(local.authorizers)

  name               = "${local.name_prefix}-authorizer"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  inline_policy {
    name   = "lambda_invoke"
    policy = data.aws_iam_policy_document.auth_inline_policy.json

  }
}

data "aws_iam_policy_document" "auth_inline_policy" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [data.aws_lambda_function.auth[count.index].arn]
  }
}
