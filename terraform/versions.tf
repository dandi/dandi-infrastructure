terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
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
