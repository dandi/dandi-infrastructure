resource "aws_s3_bucket" "inventory_bucket" {
  bucket = var.inventory_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "inventory_bucket_policy" {
  statement {
    sid       = "InventoryBucketPolicy"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.inventory_bucket.arn}/*"]
    actions   = ["s3:PutObject"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    # ----------------------------------------------
    # Source buckets for inventories
    # Note: If other sources for inventories are added, they will need to be added here as well

    # Main bucket
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.dandiset_bucket.arn]
    }
    # Log bucket
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.log_bucket.arn]
    }
    # ----------------------------------------------
  }
}

resource "aws_s3_bucket_policy" "inventory_bucket_policy" {
  provider = aws

  bucket = aws_s3_bucket.inventory_bucket.id
  policy = data.aws_iam_policy_document.inventory_bucket_policy.json
}
