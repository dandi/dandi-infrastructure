resource "improvmx_domain" "dandiarchive" {
  domain = "emberarchive.org"
}

import {
  to = improvmx_domain.dandiarchive
  id = "emberarchive.org"
}

# Set up email forwards.
resource "improvmx_email_forward" "help" {
  domain            = improvmx_domain.dandiarchive.domain
  alias_name        = "help"
  destination_email = "emberarchive@jhuapl.edu"
}

resource "improvmx_email_forward" "info" {
  domain            = improvmx_domain.dandiarchive.domain
  alias_name        = "info"
  destination_email = "emberarchive@jhuapl.edu"
}

import {
  to = improvmx_email_forward.info
  id = "emberarchive.org_info"
}


//resource "improvmx_email_forward" "team" {
//  domain            = improvmx_domain.dandiarchive.domain
//  alias_name        = "team"
//  destination_email = "emberarchive@jhuapl.edu"
//}

//resource "improvmx_email_forward" "community" {
//  domain            = improvmx_domain.dandiarchive.domain
//  alias_name        = "community"
//  destination_email = "emberarchive@jhuapl.edu"
//}
