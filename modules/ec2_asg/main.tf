# Data source para obtener la plantilla de User Data
data "template_file" "init" {
  template = file("${path.module}/user_data.sh")

  vars = {
    environment = var.environment
  }
}

# 1. Load Balancer (ALB)
resource "aws_lb" "alb" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.environment}-ALB"
  }
}

# 2. Target Group
resource "aws_lb_target_group" "asg_tg" {
  name     = "${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# 3. Listener (Envía tráfico a las instancias del Target Group)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg_tg.arn
  }
}

# 4. Launch Template (Define la configuración de las instancias)
resource "aws_launch_template" "asg_lt" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.app_sg_id]
  }

  user_data = base64encode(data.template_file.init.rendered)
}

# 5. Auto Scaling Group (ASG)
resource "aws_autoscaling_group" "asg" {
  name                      = "${var.environment}-asg"
  vpc_zone_identifier       = var.public_subnet_ids
  target_group_arns         = [aws_lb_target_group.asg_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  min_size                  = var.min_instances
  max_size                  = var.max_instances
  desired_capacity          = var.desired_capacity

  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = "$Latest" # ¡CORREGIDO!
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}