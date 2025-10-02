import {
  to = module.sponsored_dandiset_bucket.aws_s3_bucket_public_access_block.dandiset_bucket
  id = "dandiarchive"
}

import {
  to = module.sponsored_embargo_bucket.aws_s3_bucket_public_access_block.dandiset_bucket
  id = "dandiarchive-embargo"
}

import {
  to = module.staging_dandiset_bucket.aws_s3_bucket_public_access_block.dandiset_bucket
  id = "dandi-api-staging-dandisets"
}

import {
  to = module.staging_embargo_bucket.aws_s3_bucket_public_access_block.dandiset_bucket
  id = "dandi-api-staging-embargo-dandisets"
}
