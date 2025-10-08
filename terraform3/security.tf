# security.tf
# セキュリティグループを定義（最小権限の原則に従う）

# ALB用セキュリティグループ
# インターネットからのHTTPS通信を受け付ける
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-sg-"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ALBへのHTTPSインバウンドルール
resource "aws_security_group_rule" "alb_https_inbound" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS traffic from internet"
  security_group_id = aws_security_group.alb.id
}

# ALBへのHTTPインバウンドルール（HTTPSへリダイレクト用）
resource "aws_security_group_rule" "alb_http_inbound" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP traffic from internet (redirect to HTTPS)"
  security_group_id = aws_security_group.alb.id
}

# ALBからECSへのアウトバウンドルール
resource "aws_security_group_rule" "alb_ecs_outbound" {
  type                     = "egress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_tasks.id
  description              = "Allow traffic to ECS tasks"
  security_group_id        = aws_security_group.alb.id
}

# ECSタスク用セキュリティグループ
# ALBとRDSへの通信のみを許可
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.project_name}-ecs-tasks-sg-"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-ecs-tasks-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ALBからECSタスクへのインバウンドルール
resource "aws_security_group_rule" "ecs_tasks_alb_inbound" {
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow traffic from ALB"
  security_group_id        = aws_security_group.ecs_tasks.id
}

# ECSタスクから全てへのアウトバウンドルール
# ECRイメージプル、RDS接続、外部API呼び出し等に必要
resource "aws_security_group_rule" "ecs_tasks_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.ecs_tasks.id
}

# RDS用セキュリティグループ
# ECSタスクからのPostgreSQL接続のみを許可
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-sg-"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ECSタスクからRDSへのインバウンドルール
resource "aws_security_group_rule" "rds_ecs_inbound" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_tasks.id
  description              = "Allow PostgreSQL traffic from ECS tasks"
  security_group_id        = aws_security_group.rds.id
}
