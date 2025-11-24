terraform {
  cloud {
    organization = "dandi"

    workspaces {
      name = "dandi-prod"
    }
  }
}

// This is the "project" account, the primary account with most resources
provider "aws" {
  region              = "us-east-2"
  allowed_account_ids = ["278212569472"]
  # Must set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY envvars
}

// The "sponsored" account, the Amazon-sponsored account with the public bucket
provider "aws" {
  alias               = "sponsored"
  region              = "us-east-2"
  allowed_account_ids = ["769362853226"]

  // This will authenticate using credentials from the project account, then assume the
  // "dandi-infrastructure" role from the sponsored account to manage resources there
  assume_role {
    role_arn = "arn:aws:iam::769362853226:role/dandi-infrastructure"
  }

  # Must set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY envvars for project account
}

provider "heroku" {
  # Must set HEROKU_EMAIL, HEROKU_API_KEY envvars
}

provider "sentry" {
  # Must set SENTRY_AUTH_TOKEN envvar
}

provider "improvmx" {
  # Must set IMPROVMX_API_TOKEN envvar
}

data "aws_canonical_user_id" "project_account" {}

data "aws_caller_identity" "project_account" {}

data "aws_canonical_user_id" "sponsored_account" {
  provider = aws.sponsored
}

data "aws_caller_identity" "sponsored_account" {
  provider = aws.sponsored
}

data "aws_region" "current" {}

data "heroku_team" "dandi" {
  name = "dandi"
}
