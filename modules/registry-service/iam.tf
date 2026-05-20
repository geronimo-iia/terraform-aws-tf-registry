

resource "aws_iam_role" "modules" {
  name_prefix        = "${var.name_prefix}-modules"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "modules_store" {
  name   = "store"
  role   = aws_iam_role.modules.id
  policy = var.store_policy
}

resource "aws_iam_role_policy" "modules_download" {
  name   = "download"
  role   = aws_iam_role.modules.id
  policy = data.aws_iam_policy_document.module_inline_policy.json
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
  tags               = var.tags
}

resource "aws_iam_role_policy" "auth_lambda_invoke" {
  name   = "lambda_invoke"
  role   = aws_iam_role.auth.id
  policy = data.aws_iam_policy_document.auth_inline_policy.json
}

data "aws_iam_policy_document" "auth_inline_policy" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [data.aws_lambda_function.auth.arn]
  }
}
