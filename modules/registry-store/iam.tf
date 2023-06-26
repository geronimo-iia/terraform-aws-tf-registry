
data "aws_iam_policy_document" "store_policy" {
  statement {
    actions = [
      "dynamodb:Query",
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:GetRecords",
      "dynamodb:Scan"
    ]
    resources = [aws_dynamodb_table.modules.arn]
  }

  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
    ]
    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*"
    ]
  }
}