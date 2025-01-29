# Record to point gui.dandiarchive.org to the Netlify hosted redirector
resource "aws_route53_record" "redirector" {
  zone_id = aws_route53_zone.dandi.zone_id
  name    = "gui"
  type    = "CNAME"
  ttl     = "300"
  records = ["redirect-dandi-emberarchive-org.netlify.com"]
}
