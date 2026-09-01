# The DANDI WebDAV service (dandidav) was sunset in August 2026, and
# webdav.dandiarchive.org now points at the Netlify hosted redirector (see
# domain_webdav.tf). The app and its custom domain are intentionally kept here
# so the app is parked rather than destroyed; the formation is held at 0 dynos.
resource "heroku_app" "webdav" {
  name   = "dandidav"
  region = "us"
  acm    = true

  organization {
    name = data.heroku_team.dandi.name
  }

  buildpacks = [
    # The Rust application is compiled and pushed to Heroku via a GitHub Action, so
    # we don't need to specify a specific buildpack here. So, we just fall back to
    # the Heroku CLI buildpack as a default.
    "https://buildpack-registry.s3.amazonaws.com/buildpacks/heroku-community/cli.tgz"
  ]
}

resource "heroku_formation" "webdav_heroku_web" {
  app_id   = heroku_app.webdav.id
  type     = "web"
  size     = "standard-2x"
  quantity = 0 # the service is sunset; the app is parked with no running dynos
}

resource "heroku_domain" "webdav" {
  app_id   = heroku_app.webdav.id
  hostname = "webdav.dandiarchive.org"
}
