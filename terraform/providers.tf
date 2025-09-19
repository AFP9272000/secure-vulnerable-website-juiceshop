terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }
}

# Primary region (where EC2 lives)
provider "aws" {
  region = var.region
}

# us-east-1 provider alias for WAF on CloudFront (global service, you have to use us-east-1, not 2)
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}
