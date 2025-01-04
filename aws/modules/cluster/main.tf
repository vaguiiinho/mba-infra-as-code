
resource "aws_launch_template" "aws_launch_template" {
  name          = "${var.prefix}-template"
  image_id      = "ami-07d9cf938edb0739b"
  instance_type = "t2.micro"

  user_data = base64encode(
    <<EOF
  #!/bin/bash
  set -e  # Fail on errors
  yum update -y
  amazon-linux-extras enable nginx1
  yum install -y nginx
  systemctl start nginx
  systemctl enable nginx
  public_ip=$(curl -s http://checkip.amazonaws.com)
  echo "<html>
    <head> <title>Hello, World!</title> </head>
    <body>
      <p>This instance is running on $public_ip</p>
    </body>
  </html>" > /usr/share/nginx/html/index.html
  systemctl restart nginx
  EOF
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = var.security_group_ids
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.prefix}-node"
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.prefix}-asg"
  desired_capacity    = 2
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.aws_launch_template.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "scale_out_policy" {
  name                   = "${var.prefix}-scale_out"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "scale_out_alarm" {
  alarm_description   = "Monitors CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_out_policy.arn]
  alarm_name          = "${var.prefix}-scale-out-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = 60
  statistic           = "Average"
  evaluation_periods  = 3
  period              = 30

  dimensions = {
    autoscaling_group_name = aws_autoscaling_group.asg.name
  }
}

resource "aws_autoscaling_policy" "scale_in_policy" {
  name                   = "${var.prefix}-scale_in"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
}

resource "aws_cloudwatch_metric_alarm" "scale_in_alarm" {
  alarm_description   = "Monitors CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_in_policy.arn]
  alarm_name          = "${var.prefix}-scale-in-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = 20
  statistic           = "Average"
  evaluation_periods  = 3
  period              = 30

  dimensions = {
    autoscaling_group_name = aws_autoscaling_group.asg.name
  }
}
