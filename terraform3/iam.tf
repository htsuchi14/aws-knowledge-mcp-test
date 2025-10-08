# iam.tf
# ECS実行ロールとタスクロールを定義

# ECSタスク実行ロール
# ECSエージェントがECRからイメージをプルし、CloudWatch Logsへログを送信するために必要
resource "aws_iam_role" "ecs_task_execution_role" {
  name_prefix = "${var.project_name}-ecs-execution-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-execution-role"
  }
}

# ECSタスク実行ロールポリシーのアタッチ
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECR KMSキーへのアクセス許可
resource "aws_iam_role_policy" "ecs_task_execution_kms_ecr" {
  name_prefix = "${var.project_name}-ecs-execution-kms-ecr-"
  role        = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.ecr.arn
      }
    ]
  })
}

# CloudWatch Logs KMSキーへのアクセス許可
resource "aws_iam_role_policy" "ecs_task_execution_kms_logs" {
  name_prefix = "${var.project_name}-ecs-execution-kms-logs-"
  role        = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.logs.arn
      }
    ]
  })
}

# ECSタスクロール
# アプリケーションコードがAWSサービスにアクセスするために必要
resource "aws_iam_role" "ecs_task_role" {
  name_prefix = "${var.project_name}-ecs-task-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-role"
  }
}

# ECSタスクロールにカスタムポリシーをアタッチ（必要に応じて追加）
# 例: S3アクセス、DynamoDBアクセス等
resource "aws_iam_role_policy" "ecs_task_policy" {
  name_prefix = "${var.project_name}-ecs-task-"
  role        = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}/*"
      }
    ]
  })
}
