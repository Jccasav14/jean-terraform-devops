# SG para el Load Balancer
resource "aws_security_group" "alb" {
  name        = "${var.environment}-ALB-SG"
  description = "Permite trafico HTTP (80) desde Internet"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG para las instancias EC2
resource "aws_security_group" "app_instance" {
  name        = "${var.environment}-App-Instance-SG"
  description = "Permite trafico desde ALB y SSH"
  vpc_id      = var.vpc_id

  # Regla de entrada: Permite tráfico HTTP (80) SÓLO desde el SG del ALB
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Regla de entrada: SSH (para ti)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Recomendado usar tu IP pública
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}