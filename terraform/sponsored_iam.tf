resource "aws_iam_group" "sponsored_writers" {
  provider = aws.sponsored

  name = "writers"
}

resource "aws_iam_group_policy" "sponsored_writers" {
  provider = aws.sponsored

  name   = "bucket-write"
  group  = aws_iam_group.sponsored_writers.name
  policy = data.aws_iam_policy_document.sponsored_writers.json
}

data "aws_iam_policy_document" "sponsored_writers" {
  version = "2012-10-17"
  statement {
    sid = "VisualEditor0"
    actions = [
      "s3:DeleteObjectTagging",
      "s3:ListBucketByTags",
      "s3:ListBucketMultipartUploads",
      "s3:GetBucketTagging",
      "s3:ListBucketVersions",
      "s3:PutObjectVersionTagging",
      "s3:ListBucket",
      "s3:DeleteObjectVersionTagging",
      "s3:GetBucketVersioning",
      "s3:GetObjectVersionTorrent",
      "s3:PutObject",
      "s3:GetObject",
      "s3:PutBucketTagging",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging",
      "s3:DeleteObject",
      "s3:GetBucketLocation",
      "s3:GetObjectVersion",
    ]
    resources = [
      "${module.sponsored_bucket.bucket_arn}/*",
      module.sponsored_bucket.bucket_arn,
    ]
  }
}
