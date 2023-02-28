module "sponsored_bucket" {
  source          = "./modules/dandiset_bucket"
  bucket_name     = "dandiarchive"
  versioning      = true
  heroku_user     = data.aws_iam_user.api
  log_bucket_name = "dandiarchive-logs"
  providers = {
    aws         = aws.sponsored
    aws.project = aws
  }
}

module "sponsored_embargo_bucket" {
  source          = "./modules/dandiset_bucket"
  bucket_name     = "dandiarchive-embargo"
  versioning      = false
  heroku_user     = data.aws_iam_user.api
  log_bucket_name = "dandiarchive-embargo-logs"
  providers = {
    aws         = aws.sponsored
    aws.project = aws
  }
}
