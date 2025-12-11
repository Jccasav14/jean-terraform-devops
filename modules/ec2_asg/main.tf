# Archivo: ../../modules/ec2_asg/main.tf (CORREGIDO Y LIMPIO DE CARACTERES)

# ----------------------------------------------------
# 1. GENERAR LA LLAVE PRIVADA LOCAL
# ----------------------------------------------------
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. CREAR EL RECURSO KEY PAIR EN AWS (el registro público)
resource "aws_key_pair" "key_pair" {
  key_name   = "${var.environment}-key"
  public_key = tls_private_key.key_pair.public_key_openssh
}

# 3. GUARDAR LA LLAVE PRIVADA EN UN ARCHIVO .PEM LOCAL
resource "local_file" "private_key" {
  content         = tls_private_key.key_pair.private_key_pem
  filename        = "${path.module}/${var.environment}-key.pem"
  file_permission = "0400"
}

# ----------------------------------------------------
# Data source para obtener la plantilla de User Data
# ----------------------------------------------------
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
  name_prefix     = "${var.environment}-lt-"
  image_id        = var.ami_id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.key_pair.key_name # Usa la llave creada

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.app_sg_id]
  }

  user_data = base64encode(data.template_file.init.rendered)
}


resource "aws_autoscaling_group" "asg" {
  name                      = "${var.environment}-asg"
  vpc_zone_identifier       = var.public_subnet_ids
  target_group_arns         = [aws_lb_target_group.asg_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  min_size                  = var.min_instances
  max_size                  = var.max_instances
  desired_capacity          = var.desired_capacity # <--- Línea problemática limpia

  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = "$Latest"
  }

  tag {
    key               = "Environment"
    value             = var.environment
    propagate_at_launch = true
  }
}