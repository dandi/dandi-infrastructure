data "sentry_organization" "this" {
  slug = "ember-archive-dandi"
}

data "sentry_team" "this" {
  organization = data.sentry_organization.this.id
  slug         = "ember-devs"
}

data "sentry_project" "this" {
  organization = data.sentry_organization.this.id
  slug         = "ember-archive-dandi-api"
}

data "sentry_key" "this" {
  organization = data.sentry_organization.this.id
  project      = data.sentry_project.this.id
}
