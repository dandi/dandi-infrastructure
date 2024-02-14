module "staging_lincset_bucket" {
  source                  = "./modules/lincset_bucket"
  bucket_name             = "linc-brain-mit-staging"
  public                  = false
  versioning              = true
  trailing_delete         = true
  allow_heroku_put_object = true
  heroku_user             = data.aws_iam_user.api_staging
  log_bucket_name         = "linc-brain-mit-staging-logs"
  providers = {
    aws         = aws
    aws.project = aws
  }
}

module "staging_embargo_bucket" {
  source          = "./modules/lincset_bucket"
  bucket_name     = "linc-brain-mit-embargo-staging"
  versioning      = false
  trailing_delete = false
  heroku_user     = data.aws_iam_user.api_staging
  log_bucket_name = "linc-brain-mit-staging-embargo-logs"
  providers = {
    aws         = aws
    aws.project = aws
  }
}