resource "aws_sns_topic" "alert_email" {
  name         = "${var.project}-security-alerts"
  display_name = "Security Alerts" # shows up in email subject/from
  tags         = local.tags
}

# Subscribe an email address to the SNS topic.  Instead of hard‑coding
# the address here, we reference the `alert_email` variable so that
# sensitive information isn’t checked into version control.  Set
# `alert_email` in tfvars file (terraform.tfvars.example).
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alert_email.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Cloudwatch alarm: CPU utilization >= 70% for 2× five‑minute periods.  The
# alarm notifies the SNS topic created above.  The email will be sent
# both when the alarm goes off and when it returns to OK.
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project}-cpu-high"
  alarm_description   = "EC2 CPUUtilization is high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.juice.id
  }

  alarm_actions = [aws_sns_topic.alert_email.arn]
  ok_actions    = [aws_sns_topic.alert_email.arn]
  tags          = local.tags
}