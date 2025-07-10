data "sentry_organization" "this" {
  slug = "dandiarchive"
}

data "sentry_team" "this" {
  organization = data.sentry_organization.this.id
  slug         = "dandidevs"
}

data "sentry_project" "api" {
  organization = data.sentry_organization.this.id
  slug         = "dandi-api"
}

data "sentry_key" "api" {
  organization = data.sentry_organization.this.id
  project      = data.sentry_project.api.id
}

data "sentry_project" "web" {
  organization = data.sentry_organization.this.id
  slug         = "dandi-gui"
}

data "sentry_key" "web" {
  organization = data.sentry_organization.this.id
  project      = data.sentry_project.web.id
}
