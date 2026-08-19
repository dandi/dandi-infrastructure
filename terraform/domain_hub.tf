# Record to point hub.dandiarchive.org to the Netlify hosted redirector.
# The DANDI JupyterHub was retired in August 2026. The redirect rule itself
# lives in dandi-archive's redirector/netlify.toml, since Netlify reads
# redirects out of the deployed build.
resource "aws_route53_record" "hub_redirector" {
  zone_id = aws_route53_zone.dandi.zone_id
  name    = "hub"
  type    = "CNAME"
  ttl     = "300"
  records = ["redirect-dandiarchive-org.netlify.app"]
}
