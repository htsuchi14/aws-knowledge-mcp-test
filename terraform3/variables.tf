# variables.tf
# 入力変数を定義

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "aws_profile" {
  description = "AWSプロファイル名"
  type        = string
  default     = "terraform-mcp-test"
}

variable "environment" {
  description = "環境名（dev, staging, prod等）"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "プロジェクト名（リソース名のプレフィックスに使用）"
  type        = string
  default     = "webapp"
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "使用するアベイラビリティゾーン"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "db_username" {
  description = "RDSのマスターユーザー名"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_name" {
  description = "初期データベース名"
  type        = string
  default     = "appdb"
}

variable "container_port" {
  description = "コンテナがリッスンするポート番号"
  type        = number
  default     = 8080
}

variable "app_count" {
  description = "ECSタスクの実行数"
  type        = number
  default     = 2
}
