variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "create_alb_sg" {
  description = "Create ALB security group"
  type        = bool
  default     = true
}

variable "create_eks_sg" {
  description = "Create EKS security group"
  type        = bool
  default     = true
}

variable "create_rds_sg" {
  description = "Create RDS security group"
  type        = bool
  default     = true
}

variable "create_lambda_sg" {
  description = "Create Lambda security group"
  type        = bool
  default     = true
}

variable "create_bastion_sg" {
  description = "Create bastion security group"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "Allowed CIDR blocks for bastion"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
