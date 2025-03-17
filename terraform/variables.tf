variable "doi_api_password" {
  type        = string
  description = "The password for the Datacite API, used to mint new DOIs during publish."
}

variable "test_doi_api_password" {
  type        = string
  description = "The password for the Datacite Test API, used to mint new DOIs on sandbox during publish."
}

variable "dev_email" {
  type        = string
  description = "The core developer email list."
}
