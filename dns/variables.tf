variable "aws_region" {
  type        = string
  description = "AWS region used for management operations"
  default     = "us-east-1"
}

variable "root_domain" {
  type        = string
  description = "Root domain managed in Route53, for example chris-nelson.dev"
}
