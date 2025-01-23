module "sponsored_dandiset_bucket" {
  source                                = "./modules/dandiset_bucket"
  bucket_name                           = "ember-dandi-archive"
  public                                = true
  versioning                            = true
  allow_cross_account_heroku_put_object = true
  heroku_user                           = data.aws_iam_user.api
  log_bucket_name                       = "ember-dandi-archive-logs"
  providers = {
    aws         = aws.sponsored
    aws.project = aws
  }
}

module "sponsored_embargo_bucket" {
  source          = "./modules/dandiset_bucket"
  bucket_name     = "ember-dandi-archive-embargo"
  versioning      = false
  heroku_user     = data.aws_iam_user.api
  log_bucket_name = "ember-dandi-archive-embargo-logs"
  providers = {
    aws         = aws.sponsored
    aws.project = aws
  }
}
