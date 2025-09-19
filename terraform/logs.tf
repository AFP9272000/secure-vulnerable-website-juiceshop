# Canonical user ID for AWS account (used as the ACL owner)
data "aws_canonical_user_id" "current" {}

# Bucket to receive CloudFront standard logs
resource "aws_s3_bucket" "logs" {
  bucket        = var.logs_bucket_name
  force_destroy = true # <— deletes ALL objects (and versions) on destroy
  tags          = merge(local.tags, { Component = "logs" })
}

# cf log delivery requires ACL permissions. keep ownership controls + ACL below.
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule { object_ownership = "BucketOwnerPreferred" }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Give CloudFront's canonical user ID permission to write logs
data "aws_cloudfront_log_delivery_canonical_user_id" "cf" {}

resource "aws_s3_bucket_acl" "logs" {
  bucket = aws_s3_bucket.logs.id

  access_control_policy {
    owner {
      id = data.aws_canonical_user_id.current.id # <-- Use canonical user id, NOT aws_s3_bucket.logs.owner_id
    }

    # Grant CloudFront's log-delivery user WRITE and READ_ACP
    grant {
      grantee {
        type = "CanonicalUser"
        id   = data.aws_cloudfront_log_delivery_canonical_user_id.cf.id
      }
      permission = "WRITE"
    }

    grant {
      grantee {
        type = "CanonicalUser"
        id   = data.aws_cloudfront_log_delivery_canonical_user_id.cf.id
      }
      permission = "READ_ACP"
    }
  }

  depends_on = [aws_s3_bucket_ownership_controls.logs]
}