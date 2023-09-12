data "aws_caller_identity" "sponsored_account" {
  provider = aws
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "dandiset_bucket" {

  bucket = var.bucket_name
  // Public access is granted via a bucket policy, not a canned ACL
  acl = "private"

  versioning {
    enabled = var.versioning
  }

  lifecycle {
    prevent_destroy = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "dandiset_bucket" {
  bucket = aws_s3_bucket.dandiset_bucket.id

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

resource "aws_s3_bucket_logging" "dandiset_bucket" {
  bucket = aws_s3_bucket.dandiset_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = ""
}

resource "aws_s3_bucket_ownership_controls" "dandiset_bucket" {
  bucket = aws_s3_bucket.dandiset_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_iam_user_policy" "dandiset_bucket_owner" {
  // The Heroku IAM user will always be in the project account
  provider = aws.project

  name = "${var.bucket_name}-ownership-policy"
  user = var.heroku_user.user_name

  policy = data.aws_iam_policy_document.dandiset_bucket_owner.json
}

data "aws_iam_policy_document" "dandiset_bucket_owner" {
  version = "2008-10-17"

  statement {
    resources = [
      "${aws_s3_bucket.dandiset_bucket.arn}",
      "${aws_s3_bucket.dandiset_bucket.arn}/*",
    ]

    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Delete*",
    ]
  }

  dynamic "statement" {
    for_each = var.allow_heroku_put_object ? [1] : []
    content {

      resources = [
        "${aws_s3_bucket.dandiset_bucket.arn}",
        "${aws_s3_bucket.dandiset_bucket.arn}/*",
      ]

      actions = ["s3:PutObject"]
    }
  }

  statement {
    resources = [
      "${aws_s3_bucket.dandiset_bucket.arn}",
      "${aws_s3_bucket.dandiset_bucket.arn}/*",
    ]

    actions = ["s3:*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "dandiset_bucket_policy" {
  provider = aws

  bucket = aws_s3_bucket.dandiset_bucket.id
  policy = data.aws_iam_policy_document.dandiset_bucket_policy.json
}

data "aws_iam_policy_document" "dandiset_bucket_policy" {
  version = "2008-10-17"

  dynamic "statement" {
    for_each = var.public ? [1] : []

    content {
      resources = [
        "${aws_s3_bucket.dandiset_bucket.arn}",
        "${aws_s3_bucket.dandiset_bucket.arn}/*",
      ]

      actions = [
        "s3:Get*",
        "s3:List*",
      ]

      principals {
        identifiers = ["*"]
        type        = "*"
      }
    }
  }

  dynamic "statement" {
    for_each = var.allow_cross_account_heroku_put_object ? [1] : []

    content {
      sid = "S3PolicyStmt-DO-NOT-MODIFY-1569973164923"
      principals {
        identifiers = ["s3.amazonaws.com"]
        type        = "Service"
      }
      actions = [
        "s3:PutObject",
      ]
      resources = [
        "${aws_s3_bucket.dandiset_bucket.arn}/*",
      ]
      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.sponsored_account.account_id]
      }
      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }
      condition {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = [aws_s3_bucket.dandiset_bucket.arn]
      }
    }
  }

  statement {
    resources = [
      "${aws_s3_bucket.dandiset_bucket.arn}",
      "${aws_s3_bucket.dandiset_bucket.arn}/*",
    ]

    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:Delete*",
    ]

    principals {
      type        = "AWS"
      identifiers = [var.heroku_user.arn]
    }
  }

  statement {
    resources = [
      "${aws_s3_bucket.dandiset_bucket.arn}",
      "${aws_s3_bucket.dandiset_bucket.arn}/*",
    ]

    actions = ["s3:*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    principals {
      type        = "AWS"
      identifiers = [var.heroku_user.arn]
    }
  }
}
