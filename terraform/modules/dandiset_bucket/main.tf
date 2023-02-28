data "aws_canonical_user_id" "log_bucket_owner_account" {}

resource "aws_s3_bucket" "dandiset_bucket" {
  bucket = var.bucket_name
  // Public access is granted via a bucket policy, not a canned ACL
  acl = "private"

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

  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
  }

  versioning {
    enabled = var.versioning
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "dandiset_bucket" {
  bucket = aws_s3_bucket.dandiset_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = var.log_bucket_name

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
    id   = data.aws_canonical_user_id.log_bucket_owner_account.id
    permissions = [
      "FULL_CONTROL",
    ]
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_user_policy" "dandiset_bucket_owner" {
  // The Heroku IAM user will always be in the project account
  provider = aws.project

  name = "${var.bucket_name}-ownership-policy"
  user = var.heroku_user.user_name

  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:Delete*",
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.dandiset_bucket.arn}",
          "${aws_s3_bucket.dandiset_bucket.arn}/*",
        ]
      },
      {
        Action = [
          "s3:*",
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.dandiset_bucket.arn}",
          "${aws_s3_bucket.dandiset_bucket.arn}/*",
        ]
        "Condition" : {
          "StringEquals" : {
            "s3:x-amz-acl" : "bucket-owner-full-control"
          }
        }
      },
    ]
  })
}

resource "aws_s3_bucket_policy" "dandiset_bucket_policy" {
  provider = aws

  bucket = aws_s3_bucket.dandiset_bucket.id
  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Principal = {
          AWS = var.heroku_user.arn
        }
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:Delete*",
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.dandiset_bucket.arn}",
          "${aws_s3_bucket.dandiset_bucket.arn}/*",
        ]
      },
      {
        Principal = {
          AWS = var.heroku_user.arn
        }
        Action = [
          "s3:*",
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.dandiset_bucket.arn}",
          "${aws_s3_bucket.dandiset_bucket.arn}/*",
        ]
        "Condition" : {
          "StringEquals" : {
            "s3:x-amz-acl" : "bucket-owner-full-control"
          }
        }
      },
    ]
  })
}
