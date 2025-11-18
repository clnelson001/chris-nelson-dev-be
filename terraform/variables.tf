variable "aws_region" {
  description = "AWS region for S3, Route53, IAM, etc."
  type        = string
  default     = "us-east-1"
}

variable "site_bucket_name" {
  description = "S3 bucket name for the static site (must be globally unique)"
  type        = string
  default     = "chris-nelson-dev-site-tf"
}

variable "root_domain" {
  description = "Root domain name (e.g., chris-nelson.dev)"
  type        = string
}

variable "github_iam_username" {
  description = "IAM username for GitHub Actions deployments"
  type        = string
  default     = "github-actions-site-deploy"
}
