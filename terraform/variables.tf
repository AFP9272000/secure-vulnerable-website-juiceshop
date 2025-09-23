##
# Variables for the Juice Shop CloudFront/WAF deployment.

# Region where you run the EC2 instance (my location defaults to us‑east‑2)
variable "region" {
  type        = string
  description = "Primary AWS region for EC2 (us-east-2, my home region)."
  default     = "us-east-2"
}

# Put the current public IP here to allow SSH (22/tcp)
variable "my_ip_cidr" {
  type        = string
  description = "IP address in CIDR notation for SSH (e.g., 1.2.3.4/32)."
}

# Can change to a specific VPC/subnet.  Set these to override
# automatic creation of a minimal VPC and subnet; otherwise the module
# finds default ones.
variable "vpc_id" {
  type        = string
  description = "VPC ID; empty means use default VPC in region."
  default     = ""
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the instance; empty means pick a default subnet."
  default     = ""
}

# EC2 bits
variable "instance_type" {
  type        = string
  description = "EC2 instance type for Juice Shop."
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name for SSH."
}

# S3 bucket for logs (must be globally unique)
variable "logs_bucket_name" {
  type        = string
  description = "S3 bucket name to store CloudFront standard logs."
}

# Small tag used across resources
variable "project" {
  type        = string
  description = "Tag/label for the project."
  default     = "juice-shop-cf-waf"
}

# Email address for SNS alerts.  This variable is used by
# `aws_sns_topic_subscription` in `alarms.tf`.  Do not commit your
# personal email address directly to version control; instead, set
# this in your `terraform.tfvars` file.
variable "alert_email" {
  type        = string
  description = "Email address to receive security alerts via SNS."
}

# Full image:tag for the Juice Shop Docker container.  Pinning to a
# specific version helps avoid supply‑chain surprises. can
# override this in the tfvars file when a new Juice Shop version is
# released.
variable "juice_shop_image" {
  type        = string
  description = "Full Docker image (including tag) for the Juice Shop container."
  default     = "bkimminich/juice-shop:15.0.0"
}