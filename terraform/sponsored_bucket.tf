module "sponsored_dandiset_bucket" {
  source          = "./modules/dandiset_bucket"
  bucket_name     = "dandiarchive"
  heroku_user     = aws_iam_user.api_heroku_user
  embargo_readers = [aws_iam_user.backup]
  log_bucket_name = "dandiarchive-logs"
  providers = {
    aws         = aws.sponsored
    aws.project = aws
  }
}
