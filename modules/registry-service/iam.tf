

resource "aws_iam_role" "modules" {
  name_prefix        = "${var.name_prefix}-modules"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  inline_policy {
    name   = "store"
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
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "module_inline_policy" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [data.aws_lambda_function.download.arn]
  }
}


resource "aws_iam_role" "auth" {
  name_prefix        = "${var.name_prefix}-authorizer"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  inline_policy {
    name   = "lambda_invoke"
    policy = data.aws_iam_policy_document.auth_inline_policy.json

  }
  tags = var.tags
}

data "aws_iam_policy_document" "auth_inline_policy" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [data.aws_lambda_function.auth.arn]
  }
}