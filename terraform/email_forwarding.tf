data "improvmx_domain" "dandiarchive" {
  domain = "emberarchive.org"
}

# Set up email forwards.
resource "improvmx_email_forward" "help" {
  domain            = data.improvmx_domain.dandiarchive.domain
  alias_name        = "help"
  destination_email = "emberarchive@jhuapl.edu"
}

resource "improvmx_email_forward" "info" {
  domain            = data.improvmx_domain.dandiarchive.domain
  alias_name        = "info"
  destination_email = "emberarchive@jhuapl.edu"
}

resource "improvmx_email_forward" "team" {
  domain            = data.improvmx_domain.dandiarchive.domain
  alias_name        = "team"
  destination_email = "emberarchive@jhuapl.edu"
}

resource "improvmx_email_forward" "community" {
  domain            = data.improvmx_domain.dandiarchive.domain
  alias_name        = "community"
  destination_email = "emberarchive@jhuapl.edu"
}
