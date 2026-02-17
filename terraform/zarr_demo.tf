resource "aws_route53_zone" "zarr_demo" {
  name = "zarr-demo.dandiarchive.org"
}

# Point the top-level zone at the zarr-demo zone
resource "aws_route53_record" "ns_zarr_demo" {
  zone_id = aws_route53_zone.dandi.zone_id
  name    = "zarr-demo"
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.zarr_demo.name_servers
}

resource "aws_route53_record" "api_zarr_demo_heroku" {
  zone_id = aws_route53_zone.zarr_demo.zone_id
  name    = "api"
  type    = "CNAME"
  ttl     = "300"
  records = [module.api_zarr_demo_heroku.cname]
}

module "api_zarr_demo_smtp" {
  source  = "kitware-resonant/resonant/heroku//modules/smtp"
  version = "3.0.0"

  fqdn            = "api.zarr-demo.dandiarchive.org"
  project_slug    = "dandi-api-zarr-demo"
  route53_zone_id = aws_route53_zone.zarr_demo.zone_id
}


module "zarr_demo_dandiset_bucket" {
  source          = "./modules/dandiset_bucket"
  bucket_name     = "dandi-api-zarr-demo-dandisets"
  heroku_user     = aws_iam_user.api_zarr_demo_heroku_user
  log_bucket_name = "dandi-api-zarr-demo-dandiset-logs"
  providers = {
    aws         = aws
    aws.project = aws
  }
}

resource "random_string" "api_zarr_demo_django_secret" {
  length  = 64
  special = false
}


module "api_zarr_demo_heroku" {
  source  = "kitware-resonant/resonant/heroku//modules/heroku"
  version = "3.0.0"

  team_name = data.heroku_team.dandi.name
  app_name  = "dandi-api-zarr-demo"
  fqdn      = "api.zarr-demo.dandiarchive.org"

  config_vars = {
    AWS_ACCESS_KEY_ID                  = aws_iam_access_key.api_zarr_demo_heroku_user.id
    AWS_DEFAULT_REGION                 = data.aws_region.current.region
    DJANGO_ALLOWED_HOSTS               = join(",", ["api.zarr-demo.dandiarchive.org"])
    DJANGO_CORS_ALLOWED_ORIGINS        = join(",", ["https://zarr-demo.dandiarchive.org", "https://neurosift.app"])
    DJANGO_CORS_ALLOWED_ORIGIN_REGEXES = join(",", ["^https:\\/\\/[0-9a-z\\-]+--zarr-demo-dandiarchive-org\\.netlify\\.app$"])
    DJANGO_DEFAULT_FROM_EMAIL          = "info@dandiarchive.org"
    DJANGO_SETTINGS_MODULE             = "dandiapi.settings.heroku_production"
    DJANGO_STORAGE_BUCKET_NAME         = module.zarr_demo_dandiset_bucket.bucket_name

    # DANDI-specific variables
    DJANGO_CELERY_WORKER_CONCURRENCY  = "2"
    DJANGO_SENTRY_DSN                 = data.sentry_key.this.dsn.public
    DJANGO_SENTRY_ENVIRONMENT         = "zarr-demo"
    DJANGO_OAUTH2_ALLOW_URI_WILDCARDS = "true"
    DJANGO_DANDI_WEB_APP_URL          = "https://zarr-demo.dandiarchive.org"
    DJANGO_DANDI_API_URL              = "https://api.zarr-demo.dandiarchive.org"
    DJANGO_DANDI_JUPYTERHUB_URL       = "https://hub.dandiarchive.org/"
    DJANGO_DANDI_DOI_API_URL          = "https://api.test.datacite.org/dois"
    DJANGO_DANDI_DOI_API_USER         = "dartlib.dandi"
    DJANGO_DANDI_DOI_API_PREFIX       = "10.80507"
    DJANGO_DANDI_DOI_PUBLISH          = "false"
    DJANGO_DANDI_INSTANCE_NAME        = "DANDI-ZARR-DEMO"
    DJANGO_DANDI_INSTANCE_IDENTIFIER  = "RRID:SCR_017571"

    # These may be removed in the future
    DJANGO_DANDI_DANDISETS_BUCKET_NAME = module.zarr_demo_dandiset_bucket.bucket_name
    DJANGO_DANDI_DEV_EMAIL             = var.dev_email
    DJANGO_DANDI_ADMIN_EMAIL           = "info@dandiarchive.org"
  }
  sensitive_config_vars = {
    AWS_SECRET_ACCESS_KEY         = aws_iam_access_key.api_zarr_demo_heroku_user.secret
    DJANGO_EMAIL_URL              = "smtp+tls://${urlencode(module.api_zarr_demo_smtp.username)}:${urlencode(module.api_zarr_demo_smtp.password)}@${module.api_zarr_demo_smtp.host}:${module.api_zarr_demo_smtp.port}"
    DJANGO_SECRET_KEY             = random_string.api_zarr_demo_django_secret.result
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

resource "heroku_formation" "api_zarr_demo_checksum_worker" {
  app_id   = module.api_zarr_demo_heroku.app_id
  type     = "checksum-worker"
  size     = "basic"
  quantity = 1
}


resource "aws_iam_user" "api_zarr_demo_heroku_user" {
  name = "dandi-api-zarr-demo-heroku"
}

resource "aws_iam_access_key" "api_zarr_demo_heroku_user" {
  user = aws_iam_user.api_zarr_demo_heroku_user.name
}
