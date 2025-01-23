terraform {
  backend "remote" {
    organization = "BBQS-EMBER"

    workspaces {
      name = "ember-dandi-infrastructure"
    }
  }
}

// This is the "project" account, the primary account with most resources
// REDD-EMBER AWS Account
provider "aws" {
  alias               = "production"
  region              = "us-east-1"
  allowed_account_ids = ["503561422188"]
  # Must set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY envvars in Terraform
}

// The "sponsored" account, the Amazon-sponsored account with the public bucket
// REDD-EMBER-dev AWS Account
// TODO: Change to Open Data Bucket Account once we've tested (EMBER-DEV AWS account)
provider "aws" {
  alias               = "sponsored"
  region              = "us-east-1"
  allowed_account_ids = ["886436969878"]

  // This will authenticate using credentials from the project account, then assume the
  // "dandi-infrastructure" role from the sponsored account to manage resources there
  assume_role {
    role_arn = "arn:aws:iam::886436969878:role/dandi-infrastructure"  
  }

  # Must set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY envvars for project account in Terraform
}

provider "heroku" {
  # Must set HEROKU_EMAIL, HEROKU_API_KEY envvars in Terraform
}

provider "sentry" {
  # Must set SENTRY_AUTH_TOKEN envvar in Terraform
}

data "aws_canonical_user_id" "project_account" {}

data "aws_caller_identity" "project_account" {}

data "aws_canonical_user_id" "sponsored_account" {
  provider = aws.sponsored
}

data "aws_caller_identity" "sponsored_account" {
  provider = aws.sponsored
}
