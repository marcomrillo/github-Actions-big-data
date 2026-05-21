variable "project" {}
variable "env" {}
variable "glue_role_arn" {}
variable "script_location" {}

variable "raw_bucket" {}
variable "staging_bucket" {}
variable "temp_bucket" {}

variable "tags" {
  type = map(string)
}