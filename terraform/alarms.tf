resource "aws_sns_topic" "alert_email" {
  name         = "${var.project}-security-alerts"
  display_name = "Security Alerts" # shows up in email subject/from
  tags         = local.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alert_email.arn
  protocol  = "email"
  endpoint  = "addisonpirlo2@gmail.com" # (replace with any email)
}

# Cloudwatch alarm: cpu utilization >= 70% for 2x 5 minute periods
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
  ok_actions    = [aws_sns_topic.alert_email.arn] # email when back to normal
  tags          = local.tags
}