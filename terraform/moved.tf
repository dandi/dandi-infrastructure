moved {
  from = module.api.module.heroku
  to   = module.api_heroku
}
moved {
  from = module.api_sandbox.module.heroku
  to   = module.api_sandbox_heroku
}
moved {
  from = module.api.module.smtp
  to   = module.api_smtp
}
moved {
  from = module.api_sandbox.module.smtp
  to   = module.api_sandbox_smtp
}

moved {
  from = module.api.random_string.django_secret
  to   = random_string.api_django_secret
}
moved {
  from = module.api_sandbox.random_string.django_secret
  to   = random_string.api_sandbox_django_secret
}
moved {
  from = module.api.aws_route53_record.heroku
  to   = aws_route53_record.api_heroku
}
moved {
  from = module.api_sandbox.aws_route53_record.heroku
  to   = aws_route53_record.api_sandbox_heroku
}
moved {
  from = module.api.aws_iam_user.heroku_user
  to   = aws_iam_user.api_heroku_user
}
moved {
  from = module.api_sandbox.aws_iam_user.heroku_user
  to   = aws_iam_user.api_sandbox_heroku_user
}
moved {
  from = module.api.aws_iam_access_key.heroku_user
  to   = aws_iam_access_key.api_heroku_user
}
moved {
  from = module.api_sandbox.aws_iam_access_key.heroku_user
  to   = aws_iam_access_key.api_sandbox_heroku_user
}

moved {
  from = heroku_formation.api_staging_checksum_worker
  to = heroku_formation.api_sandbox_checksum_worker
}

moved {
  from = aws_route53_record.gui-sandbox
  to = aws_route53_record.gui_sandbox
}
