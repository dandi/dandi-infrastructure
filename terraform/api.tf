data "heroku_team" "dandi" {
  name = "ember-dandi"
}

module "api" {
  source  = "girder/girder4/heroku"
  version = "0.13.0"

  project_slug     = "dandi-api"
  heroku_team_name = data.heroku_team.dandi.name
  route53_zone_id  = aws_route53_zone.dandi.zone_id
  subdomain_name   = "api"

  heroku_web_dyno_size    = "standard-2x"
  heroku_worker_dyno_size = "standard-2x"
  heroku_postgresql_plan  = "standard-0"
  heroku_cloudamqp_plan   = "squirrel-1"
  heroku_papertrail_plan  = "liatorp"

  heroku_web_dyno_quantity    = 3
  heroku_worker_dyno_quantity = 1

  django_default_from_email          = "bbqs-ember-admin.jhuapl.edu"
  django_cors_origin_whitelist       = ["https://dandi.ember-archive.org"]
  django_cors_origin_regex_whitelist = ["^https:\\/\\/[0-9a-z\\-]+--gui-dandi-ember-archive-org\\.netlify\\.app$"]

  additional_django_vars = {
    DJANGO_CONFIGURATION                           = "HerokuProductionConfiguration"
    DJANGO_DANDI_DANDISETS_BUCKET_NAME             = module.sponsored_dandiset_bucket.bucket_name
    DJANGO_DANDI_DANDISETS_BUCKET_PREFIX           = ""
    DJANGO_DANDI_DANDISETS_EMBARGO_BUCKET_NAME     = module.sponsored_embargo_bucket.bucket_name
    DJANGO_DANDI_DANDISETS_EMBARGO_BUCKET_PREFIX   = ""
    DJANGO_DANDI_DANDISETS_LOG_BUCKET_NAME         = module.sponsored_dandiset_bucket.log_bucket_name
    DJANGO_DANDI_DANDISETS_EMBARGO_LOG_BUCKET_NAME = module.sponsored_embargo_bucket.log_bucket_name
    DJANGO_DANDI_DOI_API_URL                       = "https://api.datacite.org/dois" // TODO ??
    DJANGO_DANDI_DOI_API_USER                      = "dartlib.dandi"
    DJANGO_DANDI_DOI_API_PREFIX                    = "10.48324"
    DJANGO_DANDI_DOI_PUBLISH                       = "true"
    DJANGO_SENTRY_DSN                              = data.sentry_key.this.dsn_public
    DJANGO_SENTRY_ENVIRONMENT                      = "production"
    DJANGO_CELERY_WORKER_CONCURRENCY               = "4"
    DJANGO_DANDI_WEB_APP_URL                       = "https://dandi.ember-archive.org"
    DJANGO_DANDI_API_URL                           = "https://api-dandi.ember-archive.org"
    DJANGO_DANDI_JUPYTERHUB_URL                    = "https://hub-dandi.ember-archive.org/"
    DJANGO_DANDI_DEV_EMAIL                         = var.dev_email
  }
  additional_sensitive_django_vars = {
    DJANGO_DANDI_DOI_API_PASSWORD = var.doi_api_password
  }
}

resource "heroku_formation" "api_checksum_worker" {
  app_id   = module.api.heroku_app_id
  type     = "checksum-worker"
  size     = "standard-2x"
  quantity = 1
}

resource "heroku_formation" "api_analytics_worker" {
  app_id   = module.api.heroku_app_id
  type     = "analytics-worker"
  size     = "standard-1x"
  quantity = 1
}

data "aws_iam_user" "api" {
  user_name = module.api.heroku_iam_user_id
}
