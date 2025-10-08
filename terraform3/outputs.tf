# outputs.tf
# Terraform実行後に表示する出力値を定義

output "vpc_id" {
  description = "VPCのID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "パブリックサブネットのIDリスト"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "プライベートサブネットのIDリスト"
  value       = aws_subnet.private[*].id
}

output "alb_dns_name" {
  description = "ALBのDNS名（アプリケーションアクセス用URL）"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ALBのARN"
  value       = aws_lb.main.arn
}

output "ecr_repository_url" {
  description = "ECRリポジトリのURL（Dockerイメージプッシュ先）"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "ECSクラスター名"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECSサービス名"
  value       = aws_ecs_service.app.name
}

output "rds_endpoint" {
  description = "RDSエンドポイント（接続先ホスト名）"
  value       = aws_db_instance.main.endpoint
}

output "rds_database_name" {
  description = "RDSデータベース名"
  value       = aws_db_instance.main.db_name
}

output "rds_username" {
  description = "RDSマスターユーザー名"
  value       = var.db_username
  sensitive   = true
}

output "db_password_secret_arn" {
  description = "Secrets ManagerのDBパスワードシークレットARN"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch LogsグループName"
  value       = aws_cloudwatch_log_group.ecs.name
}
