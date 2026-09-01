# Record to point webdav.dandiarchive.org to the Netlify hosted redirector.
# The DANDI WebDAV server (dandidav) was retired in August 2026. The redirect
# rule itself lives in dandi-archive's redirector/netlify.toml, since Netlify
# reads redirects out of the deployed build.
resource "aws_route53_record" "webdav_redirector" {
  zone_id = aws_route53_zone.dandi.zone_id
  name    = "webdav"
  type    = "CNAME"
  ttl     = "300"
  records = ["redirect-dandiarchive-org.netlify.app"]
}
