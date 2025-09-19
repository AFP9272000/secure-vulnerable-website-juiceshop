# Region where you run the EC2 instance (my location defaults to us-east-2)
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

# Can change to a specific VPC/subnet, set these; otherwise the module finds default ones
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

# S3 bucket for logs (globally unique)
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
