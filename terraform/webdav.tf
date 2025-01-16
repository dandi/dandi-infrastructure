// resource "heroku_app" "webdav" {
//   name   = "emberdandidav"
//   region = "us"
//   acm    = true
// 
//   organization {
//     name = data.heroku_team.dandi.name
//   }
// 
//   buildpacks = [
//     # The Rust application is compiled and pushed to Heroku via a GitHub Action, so
//     # we don't need to specify a specific buildpack here. So, we just fall back to
//     # the Heroku CLI buildpack as a default.
//     "https://buildpack-registry.s3.amazonaws.com/buildpacks/heroku-community/cli.tgz"
//   ]
// }
// 
// resource "heroku_formation" "webdav_heroku_web" {
//   app_id   = heroku_app.webdav.id
//   type     = "web"
//   size     = "standard-2x"
//   quantity = 1
// }
// 
// resource "heroku_domain" "webdav" {
//   app_id   = heroku_app.webdav.id
//   hostname = "webdav-dandi.ember-archive.org"
// }
// 
// resource "aws_route53_record" "heroku" {
//   zone_id = aws_route53_zone.dandi.zone_id
//   name    = "webdav"
//   type    = "CNAME"
//   ttl     = "300"
//   records = [heroku_domain.webdav.cname]
// }
