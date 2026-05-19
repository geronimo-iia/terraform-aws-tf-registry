module "test" {
  #checkov:skip=CKV_TF_1:Example file - commit hash not applicable for registry source
  #checkov:skip=CKV_TF_2:Example file - version intentionally omitted to show latest usage
  source = "registry.my-domain.com/data/kinesis-firehose/aws"
}
