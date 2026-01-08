# ==============================================================================
# Security Groups Module
# ==============================================================================

# -----------------------------------------------------------------------------
# ALB Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  count       = var.create_alb_sg ? 1 : 0
  name        = "${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.environment}-alb-sg" })

  lifecycle { create_before_destroy = true }
}

# -----------------------------------------------------------------------------
# EKS Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "eks" {
  count       = var.create_eks_sg ? 1 : 0
  name        = "${var.environment}-eks-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description     = "Allow from ALB"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = var.create_alb_sg ? [aws_security_group.alb[0].id] : []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.environment}-eks-sg" })

  lifecycle { create_before_destroy = true }
}

# -----------------------------------------------------------------------------
# RDS Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "rds" {
  count       = var.create_rds_sg ? 1 : 0
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS databases"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "MySQL from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description     = "PostgreSQL from EKS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.create_eks_sg ? [aws_security_group.eks[0].id] : []
  }

  ingress {
    description     = "PostgreSQL from Lambda"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.create_lambda_sg ? [aws_security_group.lambda[0].id] : []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.environment}-rds-sg" })

  lifecycle { create_before_destroy = true }
}

# -----------------------------------------------------------------------------
# Lambda Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "lambda" {
  count       = var.create_lambda_sg ? 1 : 0
  name        = "${var.environment}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.environment}-lambda-sg" })

  lifecycle { create_before_destroy = true }
}

# -----------------------------------------------------------------------------
# Bastion Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "bastion" {
  count       = var.create_bastion_sg ? 1 : 0
  name        = "${var.environment}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.environment}-bastion-sg" })

  lifecycle { create_before_destroy = true }
}
