# ==============================================================================
# VPC Module - Enterprise Grade Network Infrastructure
# ==============================================================================

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.primary_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, { Name = var.vpc_name })
}

# Secondary CIDR blocks (for K8s pod pools or expansion)
resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  for_each   = toset(var.secondary_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = each.value
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.vpc_name}-igw" })
}

# -----------------------------------------------------------------------------
# Public Subnets
# -----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                     = "${var.vpc_name}-public-${substr(var.availability_zones[count.index], -2, -1)}"
    "kubernetes.io/role/elb" = "1"
    Tier                     = "public"
  })
}

# -----------------------------------------------------------------------------
# Private Subnets (Application Layer)
# -----------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name                              = "${var.vpc_name}-private-${substr(var.availability_zones[count.index], -2, -1)}"
    "kubernetes.io/role/internal-elb" = "1"
    Tier                              = "private"
  })
}

# -----------------------------------------------------------------------------
# Database Subnets (Data Layer - Isolated)
# -----------------------------------------------------------------------------
resource "aws_subnet" "database" {
  count             = length(var.database_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-database-${substr(var.availability_zones[count.index], -2, -1)}"
    Tier = "database"
  })
}

# RDS Subnet Group
resource "aws_db_subnet_group" "database" {
  count       = length(var.database_subnets) > 0 ? 1 : 0
  name        = "${var.vpc_name}-db-subnet-group"
  description = "Database subnet group for ${var.vpc_name}"
  subnet_ids  = aws_subnet.database[*].id

  tags = merge(var.tags, { Name = "${var.vpc_name}-db-subnet-group" })
}

# -----------------------------------------------------------------------------
# NAT Gateway
# -----------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.vpc_name}-nat-eip-${count.index + 1}" })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, { Name = "${var.vpc_name}-nat-${count.index + 1}" })

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# Route Tables
# -----------------------------------------------------------------------------

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.vpc_name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables
resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = var.single_nat_gateway ? "${var.vpc_name}-private-rt" : "${var.vpc_name}-private-rt-${substr(var.availability_zones[count.index], -2, -1)}"
  })
}

resource "aws_route" "private_nat" {
  count                  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}

# Database Route Tables (isolated - no NAT)
resource "aws_route_table" "database" {
  count  = length(var.database_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.vpc_name}-database-rt" })
}

resource "aws_route_table_association" "database" {
  count          = length(var.database_subnets)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[0].id
}

# -----------------------------------------------------------------------------
# VPC Flow Logs
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc/${var.vpc_name}/flow-logs"
  retention_in_days = var.flow_logs_retention_days
  tags              = var.tags
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.vpc_name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.vpc_name}-flow-logs-policy"
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "main" {
  count           = var.enable_flow_logs ? 1 : 0
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(var.tags, { Name = "${var.vpc_name}-flow-logs" })
}

# -----------------------------------------------------------------------------
# VPC Endpoints
# -----------------------------------------------------------------------------
resource "aws_security_group" "vpc_endpoints" {
  count       = length(var.vpc_endpoints) > 0 ? 1 : 0
  name_prefix = "${var.vpc_name}-vpce-"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.primary_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.vpc_name}-vpce-sg" })

  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_endpoint" "this" {
  for_each          = var.vpc_endpoints
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.${each.value.service}"
  vpc_endpoint_type = each.value.type

  route_table_ids = each.value.type == "Gateway" ? concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id,
    length(var.database_subnets) > 0 ? [aws_route_table.database[0].id] : []
  ) : null

  subnet_ids          = each.value.type == "Interface" ? aws_subnet.private[*].id : null
  security_group_ids  = each.value.type == "Interface" ? [aws_security_group.vpc_endpoints[0].id] : null
  private_dns_enabled = each.value.type == "Interface" ? lookup(each.value, "private_dns_enabled", true) : null

  tags = merge(var.tags, { Name = "${var.vpc_name}-${each.value.service}-endpoint" })
}

# Data Sources
data "aws_region" "current" {}
