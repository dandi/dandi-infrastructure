data "heroku_team" "dandi" {
  name = "dandi"
}

module "api" {
  source  = "girder/girder4/heroku"
  version = "0.11.0"

  project_slug     = "dandi-api"
  heroku_team_name = data.heroku_team.dandi.name
  route53_zone_id  = aws_route53_zone.dandi.zone_id
  subdomain_name   = "api"

  heroku_web_dyno_size    = "standard-2x"
  heroku_worker_dyno_size = "standard-2x"
  heroku_postgresql_plan  = "standard-0"
  heroku_cloudamqp_plan   = "squirrel-1"
  heroku_papertrail_plan  = "volmar"

  heroku_web_dyno_quantity    = 1
  heroku_worker_dyno_quantity = 1

  django_default_from_email          = "admin@api.dandiarchive.org"
  django_cors_origin_whitelist       = ["https://dandiarchive.org"]
  django_cors_origin_regex_whitelist = ["^https:\\/\\/[0-9a-z\\-]+--gui-dandiarchive-org\\.netlify\\.app$"]

  additional_django_vars = {
    DJANGO_CONFIGURATION                         = "HerokuProductionConfiguration"
    DJANGO_DANDI_DANDISETS_BUCKET_NAME           = module.sponsored_bucket.bucket_name
    DJANGO_DANDI_DANDISETS_BUCKET_PREFIX         = ""
    DJANGO_DANDI_DANDISETS_EMBARGO_BUCKET_NAME   = module.sponsored_embargo_bucket.bucket_name
    DJANGO_DANDI_DANDISETS_EMBARGO_BUCKET_PREFIX = ""
    DJANGO_DANDI_DOI_API_URL                     = "https://api.datacite.org/dois"
    DJANGO_DANDI_DOI_API_USER                    = "dartlib.dandi"
    DJANGO_DANDI_DOI_API_PREFIX                  = "10.48324"
    DJANGO_DANDI_DOI_PUBLISH                     = "true"
    DJANGO_SENTRY_DSN                            = "https://4bd48b5174ea4b42a130e63ebe3d60d2@o308436.ingest.sentry.io/5266078"
    DJANGO_SENTRY_ENVIRONMENT                    = "production"
    DJANGO_CELERY_WORKER_CONCURRENCY             = "4"
    DJANGO_DANDI_WEB_APP_URL                     = "https://dandiarchive.org"
    DJANGO_DANDI_API_URL                         = "https://api.dandiarchive.org"
    DJANGO_DANDI_JUPYTERHUB_URL                  = "https://hub.dandiarchive.org/"
  }
  additional_sensitive_django_vars = {
    DJANGO_DANDI_DOI_API_PASSWORD = var.doi_api_password
  }
}

resource "heroku_formation" "api_checksum_worker" {
  app      = module.api.heroku_app_id
  type     = "checksum-worker"
  size     = "standard-2x"
  quantity = 1
}

data "aws_iam_user" "api" {
  user_name = module.api.heroku_iam_user_id
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
      module.sponsored_bucket.bucket_arn,
      "${module.sponsored_bucket.bucket_arn}/*",
    ]
  }
}
