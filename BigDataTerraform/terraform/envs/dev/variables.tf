variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "tags" {
  type = map(string)
}

# AGREGA ESTO:
variable "aws_region" {
  type    = string
  default = "us-east-1" 
}