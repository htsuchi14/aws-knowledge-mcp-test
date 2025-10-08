# rds.tf
# RDS PostgreSQLインスタンスを定義

# DBサブネットグループ
# RDSインスタンスを複数のプライベートサブネットに配置
resource "aws_db_subnet_group" "main" {
  name_prefix = "${var.project_name}-db-subnet-"
  subnet_ids  = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# RDSパラメータグループ
# PostgreSQL固有の設定を管理
resource "aws_db_parameter_group" "main" {
  name_prefix = "${var.project_name}-pg-"
  family      = "postgres16"
  description = "Custom parameter group for PostgreSQL 16"

  # SSL接続を強制
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  # ログ設定
  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_duration"
    value = "1"
  }

  tags = {
    Name = "${var.project_name}-db-param-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Secrets Managerシークレット（DBパスワード）
resource "aws_secretsmanager_secret" "db_password" {
  name_prefix             = "${var.project_name}-db-password-"
  description             = "RDS PostgreSQL master password"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-db-password"
  }
}

# ランダムパスワードの生成
resource "random_password" "db_password" {
  length  = 32
  special = true
  # PostgreSQLで使用できない特殊文字を除外
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# パスワードをSecrets Managerに保存
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

# RDS PostgreSQLインスタンス
resource "aws_db_instance" "main" {
  identifier_prefix = "${var.project_name}-db-"

  # エンジン設定
  engine         = "postgres"
  engine_version = "16.3"
  instance_class = "db.t3.micro"

  # ストレージ設定
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  # データベース設定
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  port     = 5432

  # ネットワーク設定
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # マルチAZ構成（本番環境推奨）
  multi_az = false

  # パラメータとオプショングループ
  parameter_group_name = aws_db_parameter_group.main.name

  # バックアップ設定
  backup_retention_period   = 7
  backup_window             = "03:00-04:00"
  maintenance_window        = "mon:04:00-mon:05:00"
  delete_automated_backups  = true
  copy_tags_to_snapshot     = true
  skip_final_snapshot       = true
  final_snapshot_identifier = null

  # 削除保護（本番環境では有効化推奨）
  deletion_protection = false

  # CloudWatch Logsへのエクスポート
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # 自動マイナーバージョンアップグレード
  auto_minor_version_upgrade = true

  # パフォーマンスインサイト
  performance_insights_enabled    = false
  performance_insights_kms_key_id = null

  # IAMデータベース認証
  iam_database_authentication_enabled = false

  tags = {
    Name = "${var.project_name}-postgres-db"
  }
}

# Secrets ManagerからDBパスワードを読み取る権限をECSタスク実行ロールに付与
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name_prefix = "${var.project_name}-ecs-secrets-"
  role        = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.db_password.arn
      }
    ]
  })
}
