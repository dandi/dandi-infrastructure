module "api_sandbox_smtp" {
  source  = "kitware-resonant/resonant/heroku//modules/smtp"
  version = "3.0.0"

  fqdn            = "api-dandi.sandbox.emberarchive.org"
  project_slug    = "ember-dandi-api-sandbox"
  route53_zone_id = aws_route53_zone.dandi_sandbox.zone_id
}

resource "random_string" "api_sandbox_django_secret" {
  length  = 64
  special = false
}

# import {
#   to = module.api_sandbox_heroku.heroku_addon.heroku_postgresql
#   id = "ember-dandi-api-sandbox::postgresql-horizontal-05801"
# }


module "api_sandbox_heroku" {
  source  = "kitware-resonant/resonant/heroku//modules/heroku"
  version = "3.0.0"

  team_name = data.heroku_team.dandi.name
  app_name  = "ember-dandi-api-sandbox"
  fqdn      = "api-dandi.sandbox.emberarchive.org"

  config_vars = {
    AWS_ACCESS_KEY_ID                  = aws_iam_access_key.api_sandbox_heroku_user.id
    AWS_DEFAULT_REGION                 = data.aws_region.current.region
    DJANGO_ALLOWED_HOSTS               = join(",", ["dandi.sandbox.emberarchive.org", "ember-dandi-archive-sandbox.netlify.app", "api-dandi.sandbox.emberarchive.org"])
    DJANGO_CORS_ALLOWED_ORIGINS        = join(",", concat(["https://dandi.sandbox.emberarchive.org"], local.allowed_external_services))
    DJANGO_CORS_ALLOWED_ORIGIN_REGEXES = join(",", ["^https:\\/\\/[0-9a-z\\-]+--dandi-sandbox-emberarchive-org\\.netlify\\.app$", "^https:\\/\\/[0-9a-z\\-]+--ember-dandi-archive\\.netlify\\.app$"])
    DJANGO_DEFAULT_FROM_EMAIL          = "info@emberarchive.org"
    DJANGO_SETTINGS_MODULE             = "dandiapi.settings.heroku_production"
    DJANGO_STORAGE_BUCKET_NAME         = module.staging_dandiset_bucket.bucket_name

    # DANDI-specific variables
    DJANGO_CELERY_WORKER_CONCURRENCY  = "2"
    DJANGO_SENTRY_DSN                 = data.sentry_key.this.dsn.public
    DJANGO_SENTRY_ENVIRONMENT         = "staging"
    DJANGO_OAUTH2_ALLOW_URI_WILDCARDS = "true"
    DJANGO_DANDI_WEB_APP_URL          = "https://dandi.sandbox.emberarchive.org"
    DJANGO_DANDI_API_URL              = "https://api-dandi.sandbox.emberarchive.org"
    DJANGO_DANDI_JUPYTERHUB_URL       = "https://hub.dandiarchive.org/"
    DJANGO_DANDI_DOI_API_URL          = "https://api.test.datacite.org/dois"
    DJANGO_DANDI_DOI_API_USER         = "JHU.NXHEVY"
    DJANGO_DANDI_DOI_API_PREFIX       = "10.82754"
    DJANGO_DANDI_DOI_PUBLISH          = "false"
    DJANGO_DANDI_INSTANCE_NAME        = "EMBER-DANDI-SANDBOX"
    DJANGO_DANDI_INSTANCE_IDENTIFIER  = "RRID:SCR_026700"
    DJANGO_DANDI_LICENSES             = jsonencode(["spdx:CC0-1.0", "spdx:CC-BY-4.0", "spdx:CC-BY-NC-SA-4.0"])

    # These may be removed in the future
    DJANGO_DANDI_DANDISETS_BUCKET_NAME   = module.staging_dandiset_bucket.bucket_name
    DJANGO_DANDI_DEV_EMAIL               = var.dev_email
    DJANGO_DANDI_ADMIN_EMAIL             = "info@emberarchive.org"
  }
  sensitive_config_vars = {
    AWS_SECRET_ACCESS_KEY         = aws_iam_access_key.api_sandbox_heroku_user.secret
    DJANGO_EMAIL_URL              = "smtp+tls://${urlencode(module.api_sandbox_smtp.username)}:${urlencode(module.api_sandbox_smtp.password)}@${module.api_sandbox_smtp.host}:${module.api_sandbox_smtp.port}"
    DJANGO_SECRET_KEY             = random_string.api_sandbox_django_secret.result
    DJANGO_DANDI_DOI_API_PASSWORD = var.test_doi_api_password
  }

  web_dyno_size        = "basic" // "standard-2x"
  web_dyno_quantity    = 1
  worker_dyno_size     = "basic" // "standard-2x"
  worker_dyno_quantity = 1
  postgresql_plan      = "essential-0" // "standard-0"
  cloudamqp_plan       = "ermine" // "squirrel-1"
  papertrail_plan      = "choklad" // "fixa"
}

resource "heroku_formation" "api_sandbox_checksum_worker" {
  app_id   = module.api_sandbox_heroku.app_id
  type     = "checksum-worker"
  size     = "basic" // "standard-2x"
  quantity = 1
}

resource "aws_route53_record" "api_sandbox_heroku" {
  zone_id = aws_route53_zone.dandi_sandbox.zone_id
  name    = "api-dandi"
  type    = "CNAME"
  ttl     = "300"
  records = [module.api_sandbox_heroku.cname]
}

resource "aws_iam_user" "api_sandbox_heroku_user" {
  name = "ember-dandi-api-sandbox-heroku"
}

resource "aws_iam_access_key" "api_sandbox_heroku_user" {
  user = aws_iam_user.api_sandbox_heroku_user.name
}
