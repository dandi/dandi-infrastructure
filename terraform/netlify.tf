data "netlify_team" "team" {
  slug = "dandi"
}

data "netlify_site" "web" {
  team_slug = data.netlify_team.team.slug
  name      = "gui-dandiarchive-org"
}

resource "netlify_site_build_settings" "web" {
  site_id           = data.netlify_site.web.id
  build_command     = "git fetch --tags && yarn run build"
  production_branch = "release"
  publish_directory = "dist"

  base_directory             = "web"
  branch_deploy_all_branches = false
  build_image                = "focal"
  deploy_previews            = false
  # functions_directory        = "web/netlify/functions"
  functions_region = "us-east-1"
  pretty_urls      = true
}

resource "netlify_site_domain_settings" "web" {
  site_id       = data.netlify_site.web.id
  custom_domain = aws_route53_zone.dandi.name
}

locals {
  netlify_environment_variables = {
    "VITE_APP_DANDI_API_ROOT"     = module.api.all_django_vars["DJANGO_DANDI_API_URL"],
    "VITE_APP_FOOTER_BANNER_TEXT" = "This repository is under review by NIH for potential modification in compliance with U.S. federal Administration directives.",
    "VITE_APP_OAUTH_API_ROOT"     = "${trimsuffix(module.api.all_django_vars["DJANGO_DANDI_API_URL"], "/")}/oauth/",
    # From https://github.com/dandi/dandi-archive/blob/245fdb4edbc8a93a6c388a84d0b2fc3bb1c5c7ea/web/.env.production#L2
    "VITE_APP_OAUTH_CLIENT_ID"    = "Dk0zosgt1GAAKfN8LT4STJmLJXwMDPbYWYzfNtAl",
    "VITE_APP_SENTRY_DSN"         = data.sentry_key.web.dsn_public,
    "VITE_APP_SENTRY_ENVIRONMENT" = "production",
  }
}

resource "netlify_environment_variable" "this" {
  for_each = local.netlify_environment_variables

  team_id = data.netlify_team.team.id
  site_id = data.netlify_site.web.id
  key     = each.key
  values = [
    {
      value   = each.value,
      context = "all",
    }
  ]
}
