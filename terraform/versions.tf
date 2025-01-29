terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    heroku = {
      source = "heroku/heroku"
    }
    local = {
      source = "hashicorp/local"
    }
    sentry = {
      source = "jianyuan/sentry"
    }
    improvmx = {
      source = "issyl0/improvmx"
    }
  }
}
