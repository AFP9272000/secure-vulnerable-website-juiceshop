output "cloudfront_domain" {
  description = "Public HTTPS entrypoint"
  value       = aws_cloudfront_distribution.juice.domain_name
}

output "instance_public_ip" {
  value = aws_instance.juice.public_ip
}

output "instance_public_dns" {
  value = aws_instance.juice.public_dns
}

output "logs_bucket" {
  value = aws_s3_bucket.logs.bucket
}

output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.juice.arn
}

output "waf_acl_arn" {
  value = aws_wafv2_web_acl.cf.arn
}