variable "region" {
  description = "AWS region"
  default     = "eu-west-1"
  type        = string
}

variable "environment" {
  description = "Environment to deploy to"
  type        = string
}

variable "default_email" {
  description = "Default email"
  type        = string
}
