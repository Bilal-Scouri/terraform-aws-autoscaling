resource "aws_launch_template" "launch_template" {
    key_name = "aws-key"
    image_id = "${module.discovery.images_id[0]}"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.launch_template_sg.id]
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = module.discovery.public_subnets
  target_group_arns = [aws_lb_target_group.target_group.arn]
  desired_capacity   = 1
  max_size           = 2
  min_size           = 1
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }
}

resource "aws_security_group_rule" "launch_template_ingress" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.launch_template_sg.id
}

resource "aws_security_group_rule" "launch_template_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.launch_template_sg.id
}

resource "aws_security_group" "launch_template_sg" {
    vpc_id = module.discovery.vpc_id
}

resource "aws_autoscaling_policy" "autoscaling_policy_plus" {
  name = "autoscaling_policy_plus"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "autoscaling_policy_minus" {
  name = "autoscaling_policy_minus"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_cloudwatch_metric_alarm" "alarm_plus" {
  alarm_name                = "alarm_plus"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 30
  alarm_description         = "This metric monitors ec2 cpu utilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_actions = [aws_autoscaling_policy.autoscaling_policy_plus.arn]
}

resource "aws_cloudwatch_metric_alarm" "alarm_minus" {
  alarm_name                = "alarm_minus"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 5
  alarm_description         = "This metric monitors ec2 cpu utilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_actions = [aws_autoscaling_policy.autoscaling_policy_minus.arn]
}