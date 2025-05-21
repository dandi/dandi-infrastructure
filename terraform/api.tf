data "heroku_team" "dandi" {
  name = "dandi"
}

module "api" {
  source  = "kitware-resonant/resonant/heroku"
  version = "1.1.1"

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

  # TODO: move to variables.tf?
  dandi_instance_name                = "dandi"
  dandi_instance_tld                 = "dandiarhive.org"
  dandi_instance_datacite_id         = "48324"
 
  # TODO: could we define for reuse below?
  dandi_instance_url                 = "https://${var.dandi_instance_tld}"
  
  django_default_from_email          = "admin@api.${dandi_instance_tld}"
  django_cors_origin_whitelist       = [dandi_instance_url, "https://neurosift.app"]
  django_cors_origin_regex_whitelist = ["^https:\\/\\/[0-9a-z\\-]+--gui-dandiarchive-org\\.netlify\\.app$"]

  additional_django_vars = {
    DJANGO_CONFIGURATION                           = "HerokuProductionConfiguration"
    DJANGO_DANDI_DANDISETS_BUCKET_NAME             = module.sponsored_dandiset_bucket.bucket_name
    DJANGO_DANDI_DANDISETS_BUCKET_PREFIX           = ""
    DJANGO_DANDI_DANDISETS_EMBARGO_BUCKET_NAME     = module.sponsored_embargo_bucket.bucket_name
    DJANGO_DANDI_DANDISETS_EMBARGO_BUCKET_PREFIX   = ""
    DJANGO_DANDI_DANDISETS_LOG_BUCKET_NAME         = module.sponsored_dandiset_bucket.log_bucket_name
    DJANGO_DANDI_DANDISETS_EMBARGO_LOG_BUCKET_NAME = module.sponsored_embargo_bucket.log_bucket_name
    DJANGO_DANDI_DOI_API_URL                       = "https://api.datacite.org/dois"
    DJANGO_DANDI_DOI_API_USER                      = "dartlib.dandi"
    DJANGO_DANDI_DOI_API_PREFIX                    = "10.${var.dandi_instance_datacite_id}"
    DJANGO_DANDI_DOI_PUBLISH                       = "true"
    DJANGO_SENTRY_DSN                              = data.sentry_key.this.dsn_public
    DJANGO_SENTRY_ENVIRONMENT                      = "production"
    DJANGO_CELERY_WORKER_CONCURRENCY               = "4"
    DJANGO_DANDI_WEB_APP_URL                       = var.dandi_instance_url
    DJANGO_DANDI_API_URL                           = "https://api.${var.dandi_instance_tld}"
    DJANGO_DANDI_JUPYTERHUB_URL                    = "https://hub.${var.dandi_instance_tld}"
    DJANGO_DANDI_DEV_EMAIL                         = var.dev_email
    DJANGO_DANDI_ADMIN_EMAIL                       = "info@${var.dandi_instance_tld}"
    DANDI_INSTANCE_NAME                            = var.dandi_instance_name 
    DANDI_DATACITE_DOI_ID                          = var.dandi_instance_datacite_id
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
