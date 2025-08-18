module "staging_dandiset_bucket" {
  source                  = "./modules/dandiset_bucket"
  bucket_name             = "dandi-api-staging-dandisets"
  public                  = true
  versioning              = true
  allow_heroku_put_object = true
  heroku_user             = aws_iam_user.api_sandbox_heroku_user
  log_bucket_name         = "dandi-api-staging-dandiset-logs"
  providers = {
    aws         = aws
    aws.project = aws
  }
}

module "staging_embargo_bucket" {
  source          = "./modules/dandiset_bucket"
  bucket_name     = "dandi-api-staging-embargo-dandisets"
  versioning      = false
  heroku_user     = aws_iam_user.api_sandbox_heroku_user
  log_bucket_name = "dandi-api-staging-embargo-dandisets-logs"
  providers = {
    aws         = aws
    aws.project = aws
  }
}
