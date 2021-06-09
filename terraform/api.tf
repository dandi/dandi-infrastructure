data "heroku_team" "dandi" {
  name = "dandi"
}

module "api" {
  source  = "girder/django/heroku"
  version = "0.8.0"

  project_slug     = "dandi-api"
  heroku_team_name = data.heroku_team.dandi.name
  route53_zone_id  = aws_route53_zone.dandi.zone_id
  subdomain_name   = "api"

  heroku_web_dyno_size    = "standard-1x"
  heroku_worker_dyno_size = "standard-2x"
  heroku_postgresql_plan  = "standard-0"
  heroku_cloudamqp_plan   = "tiger"
  heroku_papertrail_plan  = "volmar"

  django_cors_origin_whitelist       = ["https://gui.dandiarchive.org", "https://gui-beta-dandiarchive-org.netlify.app"]
  django_cors_origin_regex_whitelist = ["^https:\\/\\/[0-9a-z\\-]+--gui-dandiarchive-org\\.netlify\\.app$"]

  additional_django_vars = {
    # DJANGO_DANDI_DANDISETS_BUCKET_NAME = aws_s3_bucket.sponsored_bucket.id
    DJANGO_DANDI_DANDISETS_BUCKET_NAME   = aws_s3_bucket.sponsored_bucket.id
    DJANGO_DANDI_DANDISETS_BUCKET_PREFIX = ""
    DJANGO_DANDI_SCHEMA_VERSION          = "0.4.1"
    DJANGO_DANDI_DOI_API_URL             = "https://api.test.datacite.org/dois"
    DJANGO_DANDI_DOI_API_USER            = "dartlib.dandi"
    DJANGO_DANDI_DOI_API_PREFIX          = "10.80507"
    DJANGO_SENTRY_DSN                    = "https://4bd48b5174ea4b42a130e63ebe3d60d2@o308436.ingest.sentry.io/5266078"
    DJANGO_SENTRY_ENVIRONMENT            = "production"
  }
  additional_sensitive_django_vars = {
    DJANGO_DANDI_DOI_API_PASSWORD = var.doi_api_password
  }
}

data "aws_iam_user" "api" {
  user_name = module.api.iam_user_id
}

resource "aws_iam_user_policy" "api_sponsored_bucket" {
  user   = data.aws_iam_user.api.user_name
  name   = "dandi-api-sponsored-bucket"
  policy = data.aws_iam_policy_document.api_sponsored_bucket.json
}

data "aws_iam_policy_document" "api_sponsored_bucket" {
  statement {
    actions = [
      # TODO Figure out minimal set of permissions django storages needs for S3
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.sponsored_bucket.arn,
      "${aws_s3_bucket.sponsored_bucket.arn}/*",
    ]
  }
}
