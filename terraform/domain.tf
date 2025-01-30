resource "aws_route53_zone" "dandi" {
  name = "emberarchive.org"
}

resource "aws_route53_record" "acm_validation" {
  zone_id = aws_route53_zone.dandi.zone_id
  name    = "_2ab953c925117985ed729c889a811e82"
  type    = "CNAME"
  ttl     = "300"
  records = ["_369acdcce1e63f94431388fcc713b029.zfyfvmchrl.acm-validations.aws."]
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
  records = ["gui-dandi-staging-emberarchive-org.netlify.com"]
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.dandi.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "300"
  records = ["dandi.github.io"]
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

resource "aws_route53_record" "api-dandi-staging-heroku-app" {
  zone_id = aws_route53_zone.dandi.zone_id
  name    = "api-dandi-staging"
  type    = "CNAME"
  ttl     = "300"
  records = ["dry-waters-tfs5sbdos7ion2o6614l4dcm.herokudns.com"]
}

resource "aws_route53_record" "api-dandi-heroku-app" {
  zone_id = aws_route53_zone.dandi.zone_id
  name    = "api-dandi"
  type    = "CNAME"
  ttl     = "300"
  records = ["corrugated-gorilla-f2e8ls3ewsw7fv2ilslqkij0.herokudns.com"]
}
