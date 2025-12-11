
variable "environment" {
  description = "Nombre del entorno (ej: dev, prod)"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
}


variable "min_instances" {
  description = "Mínimo de instancias en el ASG"
  type        = number
}

variable "max_instances" {
  description = "Máximo de instancias en el ASG"
  type        = number
}

variable "desired_capacity" {
  description = "Capacidad deseada inicial del ASG"
  type        = number
}