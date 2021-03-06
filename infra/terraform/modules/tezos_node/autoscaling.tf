resource "aws_autoscaling_policy" "cpu_out" {
  name                   = format("tzlink-%s-%s-out-cpu", var.TZ_NETWORK, var.TZ_MODE)
  autoscaling_group_name = aws_autoscaling_group.tz_nodes.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = var.CPU_OUT_SCALING_COOLDOWN
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "cpu_down" {
  name                   = format("tzlink-%s-%s-down-cpu", var.TZ_NETWORK, var.TZ_MODE)
  autoscaling_group_name = aws_autoscaling_group.tz_nodes.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = var.CPU_DOWN_SCALING_COOLDOWN
  policy_type            = "SimpleScaling"
}


resource "aws_cloudwatch_metric_alarm" "cpu_scale_out" {
  actions_enabled = true

  alarm_name          = format("tzlink-%s-%s-out-cpu", var.TZ_NETWORK, var.TZ_MODE)
  namespace           = "AWS/EC2"
  statistic           = "Average"
  metric_name         = "CPUUtilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.CPU_OUT_SCALING_THRESHOLD

  period             = 60
  evaluation_periods = var.CPU_OUT_EVALUATION_PERIODS

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.tz_nodes.name
  }

  alarm_description = "Average CPUUtilization >= ${var.CPU_OUT_SCALING_THRESHOLD}% (duration >= ${var.CPU_OUT_EVALUATION_PERIODS}min)"
  alarm_actions     = [aws_autoscaling_policy.cpu_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_scale_down" {
  actions_enabled = true

  alarm_name          = format("tzlink-%s-%s-down-cpu", var.TZ_NETWORK, var.TZ_MODE)
  namespace           = "AWS/EC2"
  statistic           = "Average"
  metric_name         = "CPUUtilization"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = var.CPU_DOWN_SCALING_THRESHOLD

  period             = 60
  evaluation_periods = var.CPU_DOWN_EVALUATION_PERIODS

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.tz_nodes.name
  }

  alarm_description = "Average CPUUtilization <= ${var.CPU_DOWN_SCALING_THRESHOLD}% (duration >= ${var.CPU_DOWN_EVALUATION_PERIODS}min)"
  alarm_actions     = [aws_autoscaling_policy.cpu_down.arn]
}