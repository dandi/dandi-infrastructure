module "staging_dandisets_bucket" {
  source          = "./modules/dandiset_bucket"
  bucket_name     = "dandi-api-staging-dandisets"
  versioning      = true
  heroku_user     = data.aws_iam_user.api
  log_bucket_name = "dandi-api-staging-dandiset-logs"
  providers = {
    aws         = aws
    aws.project = aws
  }
}

module "staging_embargo_bucket" {
  source          = "./modules/dandiset_bucket"
  bucket_name     = "dandi-api-staging-embargo-dandisets"
  versioning      = false
  heroku_user     = data.aws_iam_user.api_staging
  log_bucket_name = "dandi-api-staging-embargo-dandisets-logs"
  providers = {
    aws         = aws
    aws.project = aws
  }
}
