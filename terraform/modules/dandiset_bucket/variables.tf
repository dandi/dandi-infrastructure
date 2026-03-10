variable "bucket_name" {
  type        = string
  description = "The name of the bucket."
}

variable "heroku_user" {
  description = "The Heroku API IAM user who will have write access to the bucket."
}

variable "embargo_readers" {
  description = "Other IAM users (besides `heroku_user`) that will have read access to embargoed objects."
  default     = []
}

variable "log_bucket_name" {
  type        = string
  description = "The name of the log bucket."
}

variable "inventory_bucket_name" {
  type        = string
  description = "Name of the shared S3 bucket where inventory reports are delivered (e.g. dandiarchive-inventory)."
}
