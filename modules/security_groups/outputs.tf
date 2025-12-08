output "alb_sg_id" {
  description = "ID del Security Group para el Load Balancer"
  value       = aws_security_group.alb.id
}

output "app_sg_id" {
  description = "ID del Security Group para las instancias de la aplicación"
  value       = aws_security_group.app_instance.id
}