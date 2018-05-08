variable "region" {
  description = "The AWS region to deploy into."
  default     = "us-east-1"
}

variable "version" {
  description = "The version (semver) of the function."
}
