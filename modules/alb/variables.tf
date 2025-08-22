#variable "project" { type = string }
variable "name_suffix" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "app_port" { type = number }
variable "health_path" { type = string }
variable "alb_certificate_arn" {
  description = "ACM cert ARN for this ALB's region. If null, HTTPS listener is not created."
  type        = string
  default     = null
}
