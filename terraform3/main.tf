# main.tf
# プロバイダー設定とデフォルトタグを定義

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "terraform-mcp-test"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
