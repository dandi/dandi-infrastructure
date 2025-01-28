resource "improvmx_domain" "dandiarchive" {
  domain = "dandiarchive.org"
}

# Retrieve and display domain check status.
data "improvmx_domain_check" "dandiarchive" {
  domain = improvmx_domain.dandiarchive.domain
}

output "domain_status" {
  value = data.improvmx_domain_check.dandiarchive
}

# Set up email forwards.
resource "improvmx_email_forward" "help" {
  domain            = improvmx_domain.dandiarchive.domain
  alias_name        = "help"
  destination_email = "dandi@mit.edu"
}

resource "improvmx_email_forward" "info" {
  domain            = improvmx_domain.dandiarchive.domain
  alias_name        = "info"
  destination_email = "dandi@mit.edu"
}

resource "improvmx_email_forward" "team" {
  domain            = improvmx_domain.dandiarchive.domain
  alias_name        = "team"
  destination_email = "dandi@mit.edu"
}

resource "improvmx_email_forward" "community" {
  domain            = improvmx_domain.dandiarchive.domain
  alias_name        = "community"
  destination_email = "kabi@mit.edu,roni.choudhury@kitware.com,satra@mit.edu,yoh@onerussian.com"
}
