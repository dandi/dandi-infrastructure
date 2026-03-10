module "staging_dandiset_bucket" {
  source                = "./modules/dandiset_bucket"
  bucket_name           = "dandi-api-staging-dandisets"
  heroku_user           = aws_iam_user.api_sandbox_heroku_user
  log_bucket_name       = "dandi-api-staging-dandiset-logs"
  inventory_bucket_name = "dandi-api-staging-inventory"
  providers = {
    aws         = aws
    aws.project = aws
  }
}
