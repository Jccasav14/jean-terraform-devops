variable "environment" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "alb_sg_id" {
  type = string
}
variable "app_sg_id" {
  type = string
}
variable "ami_id" {
  type = string
}
variable "key_name" {
  type = string
}
variable "instance_type" {
  type = string
}
variable "min_instances" {
  type = number
}
variable "max_instances" {
  type = number
}
variable "desired_capacity" {
  type = number
}