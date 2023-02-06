// TODO use the dandiset_bucket module
resource "aws_s3_bucket" "api_staging_dandisets_bucket" {

  bucket = "dandi-api-staging-dandisets"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_logging" "api_staging_dandisets_bucket" {
  bucket = aws_s3_bucket.api_staging_dandisets_bucket.id

  target_bucket = aws_s3_bucket.api_staging_dandisets_bucket_logs.id
  target_prefix = ""
}

resource "aws_s3_bucket_acl" "api_staging_dandisets_bucket" {
  bucket = aws_s3_bucket.api_staging_dandisets_bucket.id
  // Public access is granted via a bucket policy, not a canned ACL
  acl = "private"
}

resource "aws_s3_bucket_versioning" "api_staging_dandisets_bucket" {
  bucket = aws_s3_bucket.api_staging_dandisets_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_cors_configuration" "api_staging_dandisets_bucket" {
  bucket = aws_s3_bucket.api_staging_dandisets_bucket.id

  cors_rule {
    allowed_origins = [
      "*",
    ]
    allowed_methods = [
      "PUT",
      "POST",
      "GET",
      "DELETE",
    ]
    allowed_headers = [
      "*"
    ]
    expose_headers = [
      "ETag",
    ]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_ownership_controls" "api_staging_dandisets_bucket" {
  bucket = aws_s3_bucket.api_staging_dandisets_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket" "api_staging_dandisets_bucket_logs" {

  bucket = "dandi-api-staging-dandiset-logs"

  grant {
    type = "Group"
    uri  = "http://acs.amazonaws.com/groups/s3/LogDelivery"
    permissions = [
      "READ_ACP",
      "WRITE",
    ]
  }
  grant {
    type = "CanonicalUser"
    id   = data.aws_canonical_user_id.project_account.id
    permissions = [
      "FULL_CONTROL",
    ]
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_policy" "api_staging_dandisets_bucket" {
  bucket = aws_s3_bucket.api_staging_dandisets_bucket.id
  policy = data.aws_iam_policy_document.api_staging_dandisets_bucket.json
}

data "aws_iam_policy_document" "api_staging_dandisets_bucket" {
  version = "2008-10-17"

  statement {
    sid = "dandi-api-staging"
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_user.api_staging.arn]
    }
    actions = [
      "s3:*",
    ]
    resources = [
      "${aws_s3_bucket.api_staging_dandisets_bucket.arn}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid = "dandi-api-staging-delete"
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_user.api_staging.arn]
    }
    actions = [
      "s3:Delete*",
    ]
    resources = [
      "${aws_s3_bucket.api_staging_dandisets_bucket.arn}/*",
    ]
  }

  statement {
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    actions = [
      "s3:List*",
      "s3:Get*",
    ]
    resources = [
      "${aws_s3_bucket.api_staging_dandisets_bucket.arn}/*",
      aws_s3_bucket.api_staging_dandisets_bucket.arn,
    ]
  }

  statement {
    sid = "S3PolicyStmt-DO-NOT-MODIFY-1569973164923"
    principals {
      identifiers = ["s3.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.api_staging_dandisets_bucket.arn}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.project_account.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.api_staging_dandisets_bucket.arn]
    }
  }
}

module "staging_embargo_bucket" {
  source          = "./modules/dandiset_bucket"
  bucket_name     = "dandi-api-staging-embargo-dandisets"
  versioning      = false
  heroku_user     = data.aws_iam_user.api_staging
  log_bucket_name = "dandi-api-staging-embargo-dandisets-logs"
  providers = {
    aws         = aws
    aws.project = aws
  }
}
