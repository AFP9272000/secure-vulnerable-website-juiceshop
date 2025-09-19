# WAF for CloudFront must be created in us-east-1 with CLOUDFRONT scope
resource "aws_wafv2_web_acl" "cf" {
  provider = aws.use1
  name     = "${var.project}-waf"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-waf"
    sampled_requests_enabled   = true
  }

  # Managed rule sets
  rule {
    name     = "AWSCommon"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSCommon"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSBadInputs"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSBadInputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSIPRep"
    priority = 3

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSIPRep"
      sampled_requests_enabled   = true
    }
  }

  # Simple rate limit: block IPs >1000 req/5m
  rule {
    name     = "RateLimit1kPer5m"
    priority = 10

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }

    action {
      block {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }
}

# Wait briefly after CF creation to avoid propagation race
resource "time_sleep" "wait_for_cf" {
  depends_on      = [aws_cloudfront_distribution.juice]
  create_duration = "120s"
}

# Associate WAF Web ACL to the CloudFront distribution
resource "aws_wafv2_web_acl_association" "cf_assoc" {
  provider     = aws.use1
  resource_arn = aws_cloudfront_distribution.juice.arn # <-- correct: includes account ID
  web_acl_arn  = aws_wafv2_web_acl.cf.arn
  depends_on   = [time_sleep.wait_for_cf, aws_wafv2_web_acl.cf]
}
