module "sponsored_dandiset_bucket" {
  source                                = "./modules/dandiset_bucket"
  bucket_name                           = "dandiarchive"
  public                                = true
  versioning                            = true
  allow_cross_account_heroku_put_object = true
  heroku_user                           = aws_iam_user.api_heroku_user
  embargo_readers                       = [aws_iam_user.backup]
  log_bucket_name                       = "dandiarchive-logs"
  providers = {
    aws         = aws.sponsored
    aws.project = aws
  }
}

module "sponsored_embargo_bucket" {
  source          = "./modules/dandiset_bucket"
  bucket_name     = "dandiarchive-embargo"
  versioning      = false
  heroku_user     = aws_iam_user.api_heroku_user
  log_bucket_name = "dandiarchive-embargo-logs"
  providers = {
    aws         = aws.sponsored
    aws.project = aws
  }
}
