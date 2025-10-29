module "api_sandbox_smtp" {
  source  = "kitware-resonant/resonant/heroku//modules/smtp"
  version = "3.0.0"

  fqdn            = "api.sandbox.dandiarchive.org"
  project_slug    = "dandi-api-staging"
  route53_zone_id = aws_route53_zone.dandi_sandbox.zone_id
}

resource "random_string" "api_sandbox_django_secret" {
  length  = 64
  special = false
}

module "api_sandbox_heroku" {
  source  = "kitware-resonant/resonant/heroku//modules/heroku"
  version = "3.0.0"

  team_name = data.heroku_team.dandi.name
  app_name  = "dandi-api-staging"
  fqdn      = "api.sandbox.dandiarchive.org"

  config_vars = {
    AWS_ACCESS_KEY_ID                  = aws_iam_access_key.api_sandbox_heroku_user.id
    AWS_DEFAULT_REGION                 = data.aws_region.current.region
    DJANGO_ALLOWED_HOSTS               = join(",", ["api.sandbox.dandiarchive.org"])
    DJANGO_CORS_ALLOWED_ORIGINS        = join(",", ["https://sandbox.dandiarchive.org", "https://neurosift.app"])
    DJANGO_CORS_ALLOWED_ORIGIN_REGEXES = join(",", ["^https:\\/\\/[0-9a-z\\-]+--sandbox-dandiarchive-org\\.netlify\\.app$"])
    DJANGO_DEFAULT_FROM_EMAIL          = "admin@api.sandbox.dandiarchive.org"
    DJANGO_SETTINGS_MODULE             = "dandiapi.settings.heroku_production"
    DJANGO_STORAGE_BUCKET_NAME         = module.staging_dandiset_bucket.bucket_name

    # DANDI-specific variables
    DJANGO_CELERY_WORKER_CONCURRENCY  = "2"
    DJANGO_SENTRY_DSN                 = data.sentry_key.this.dsn.public
    DJANGO_SENTRY_ENVIRONMENT         = "staging"
    DJANGO_OAUTH2_ALLOW_URI_WILDCARDS = "true"
    DJANGO_DANDI_WEB_APP_URL          = "https://sandbox.dandiarchive.org"
    DJANGO_DANDI_API_URL              = "https://api.sandbox.dandiarchive.org"
    DJANGO_DANDI_JUPYTERHUB_URL       = "https://hub.dandiarchive.org/"
    DJANGO_DANDI_DOI_API_URL          = "https://api.test.datacite.org/dois"
    DJANGO_DANDI_DOI_API_USER         = "dartlib.dandi"
    DJANGO_DANDI_DOI_API_PREFIX       = "10.80507"
    DJANGO_DANDI_DOI_PUBLISH          = "false"
    DJANGO_DANDI_INSTANCE_NAME        = "DANDI-SANDBOX"
    DJANGO_DANDI_INSTANCE_IDENTIFIER  = "RRID:SCR_017571"

    # These may be removed in the future
    DJANGO_DANDI_DANDISETS_BUCKET_NAME = module.staging_dandiset_bucket.bucket_name
    DJANGO_DANDI_DEV_EMAIL             = var.dev_email
    DJANGO_DANDI_ADMIN_EMAIL           = "info@dandiarchive.org"
  }
  sensitive_config_vars = {
    AWS_SECRET_ACCESS_KEY         = aws_iam_access_key.api_sandbox_heroku_user.secret
    DJANGO_EMAIL_URL              = "smtp+tls://${urlencode(module.api_sandbox_smtp.username)}:${urlencode(module.api_sandbox_smtp.password)}@${module.api_sandbox_smtp.host}:${module.api_sandbox_smtp.port}"
    DJANGO_SECRET_KEY             = random_string.api_sandbox_django_secret.result
    DJANGO_DANDI_DOI_API_PASSWORD = var.test_doi_api_password
  }

  web_dyno_size        = "basic"
  web_dyno_quantity    = 1
  worker_dyno_size     = "basic"
  worker_dyno_quantity = 1
  postgresql_plan      = "essential-1"
  cloudamqp_plan       = "tiger"
  papertrail_plan      = "fixa"
}

resource "heroku_formation" "api_sandbox_checksum_worker" {
  app_id   = module.api_sandbox_heroku.app_id
  type     = "checksum-worker"
  size     = "basic"
  quantity = 1
}

resource "aws_route53_record" "api_sandbox_heroku" {
  zone_id = aws_route53_zone.dandi_sandbox.zone_id
  name    = "api"
  type    = "CNAME"
  ttl     = "300"
  records = [module.api_sandbox_heroku.cname]
}

resource "aws_iam_user" "api_sandbox_heroku_user" {
  name = "dandi-api-sandbox-heroku"
}

resource "aws_iam_access_key" "api_sandbox_heroku_user" {
  user = aws_iam_user.api_sandbox_heroku_user.name
}

resource "heroku_pipeline" "dandi_pipeline" {
  name = "dandi-pipeline"

  owner {
    id   = data.heroku_team.dandi.id
    type = "team"
  }
}

resource "heroku_pipeline_coupling" "staging" {
  app_id   = module.api_sandbox_heroku.app_id
  pipeline = heroku_pipeline.dandi_pipeline.id
  stage    = "staging"
}

resource "heroku_pipeline_coupling" "production" {
  app_id   = module.api_heroku.app_id
  pipeline = heroku_pipeline.dandi_pipeline.id
  stage    = "production"
}
