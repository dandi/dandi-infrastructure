variable "public" {
  type        = bool
  description = "Whether or not the contents of the bucket should be public."
  default     = false
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket."
}

# TODO: remove after migration
variable "allow_heroku_put_object" {
  type    = bool
  default = false
}

# TODO: refactor after migration
variable "allow_cross_account_heroku_put_object" {
  type    = bool
  default = false
}

variable "versioning" {
  type        = bool
  description = "Whether or not versioning should be enabled on the bucket."
}

variable "heroku_user" {
  description = "The Heroku API IAM user who will have write access to the bucket."
}

variable "log_bucket_name" {
  type        = string
  description = "The name of the log bucket."
}

# TODO: remove this after it's ready to be enabled in production
variable "enable_manifest_file_expiration" {
  type        = bool
  description = "Whether or not to enable expiration of manifest files."
  default     = false
}
