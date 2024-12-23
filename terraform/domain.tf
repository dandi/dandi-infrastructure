
// EXAMPLE

# Lookup existing hosted zone
data "aws_route53_zone" "dandi" {
  name         = "ember-archive.org" # Replace with your hosted zone name
  private_zone = false          # Set to true if it's a private zone
}

resource "aws_route53_zone" "dandi" {
  name = "ember-archive.org"

  private_zone = false          # Set to true if it's a private zone

  count = length(data.aws_route53_zone.existing.id) == 0 ? 1 : 0
}


# Use the existing or newly created hosted zone
resource "aws_route53_zone" "dandi" {
  zone_id = coalesce(
    data.aws_route53_zone.existing.id,
    aws_route53_zone.dandi[0].id
  )
}



// END

resource "aws_route53_record" "acm_validation" {
  zone_id = aws_route53_zone.dandi.zone_id
  name    = "_755ff606dac73e69c5c10c5139ec3c10"
  type    = "CNAME"
  ttl     = "300"
  records = ["_f069d074ef9a310884fa16f77695324f.zfyfvmchrl.acm-validations.aws."]
}

resource "aws_route53_record" "gui" {
  zone_id = aws_route53_zone.dandi.zone_id
  name    = "" # apex
  type    = "A"
  ttl     = "300"
  records = ["75.2.60.5"] # Netlify's load balancer, which will proxy to our app
}

resource "aws_route53_record" "gui-staging" {
  zone_id = aws_route53_zone.dandi.zone_id
  name    = "gui-staging"
  type    = "CNAME"
  ttl     = "300"
  records = ["gui-staging-dandi-ember-archive-org.netlify.com"]
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.dandi.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "300"
  records = ["dandi.github.io"] // TODO ?
}

resource "aws_route53_record" "email" {
  zone_id = aws_route53_zone.dandi.zone_id
  name    = "" # apex
  type    = "MX"
  ttl     = "300"
  records = [
    "10 mx1.improvmx.com.",
    "20 mx2.improvmx.com.",
  ]
}

resource "aws_route53_record" "email-spf" {
  zone_id = aws_route53_zone.dandi.zone_id
  name    = "" # apex
  type    = "TXT"
  ttl     = "300"
  records = ["v=spf1 include:spf.improvmx.com ~all"]
}
