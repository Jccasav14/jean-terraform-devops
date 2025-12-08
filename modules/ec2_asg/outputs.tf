output "alb_dns_name" {
  description = "DNS Name del Application Load Balancer"
  value       = aws_lb.alb.dns_name
}