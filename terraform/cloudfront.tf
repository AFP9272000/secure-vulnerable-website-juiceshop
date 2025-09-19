# Security headers at the edge (HSTS, nosniff, etc.)
resource "aws_cloudfront_response_headers_policy" "security" {
  name = "${var.project}-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
    }

    referrer_policy {
      referrer_policy = "same-origin"
      override        = true
    }

    xss_protection {
      protection = true
      mode_block = true
      override   = true
    }
  }
}

# CloudFront distribution using EC2 as a custom origin (HTTP on port 3000)
resource "aws_cloudfront_distribution" "juice" {
  enabled             = true
  comment             = "${var.project} distribution"
  default_root_object = "index.html"

  origin {
    domain_name = aws_instance.juice.public_dns
    origin_id   = "ec2-juice"

    custom_origin_config {
      http_port              = 3000
      https_port             = 443
      origin_protocol_policy = "http-only" # CloudFront->origin uses HTTP
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "ec2-juice"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    # Juice Shop has dynamic bits; forward queries/cookies to keep it simple
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  price_class = "PriceClass_100"

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Standard logs to S3 logs bucket
  logging_config {
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "cloudfront/"
    include_cookies = false
  }

  tags = local.tags
}
