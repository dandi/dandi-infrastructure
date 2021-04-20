data "local_file" "ssh_public_key" {
  filename = "girder-dandi-server_id_rsa.pub"
}

resource "aws_route53_record" "girder" {
  zone_id = aws_route53_zone.dandi.zone_id
  name    = "girder"
  type    = "A"
  ttl     = "300"
  records = [module.girder_server.ec2_ip]
}

module "girder_server" {
  source  = "girder/girder/aws//modules/server"
  version = "0.8.0"

  project_slug    = "dandi-girder"
  ssh_public_key  = data.local_file.ssh_public_key.content
  ec2_volume_size = 100
}

module "girder_smtp" {
  source  = "girder/girder/aws//modules/smtp"
  version = "0.8.0"

  project_slug    = "dandi-girder"
  route53_zone_id = aws_route53_zone.dandi.zone_id
  fqdn            = aws_route53_record.girder.fqdn
}
