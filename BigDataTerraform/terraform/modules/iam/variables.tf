variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "raw_bucket" {
  type = string
}

variable "staging_bucket" {
  type = string
}

# ◄── ESTA ES LA VARIABLE NUEVA QUE FALTABA
variable "analytics_bucket" {
  type = string
}

variable "temp_bucket" {
  type = string
}