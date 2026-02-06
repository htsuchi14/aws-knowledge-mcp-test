# aws-knowledge-mcp-test

このリポジトリは、Terraform構成の検証用サンプルをまとめたものです。

## ディレクトリ構成

- `terraform1/`: 基本的なTerraformサンプル
- `terraform2/`: 追加検証用のTerraformサンプル
- `terraform3/`: VPC/ALB/ECS/ECR/RDSを含む本格的なインフラ構成（詳細は`terraform3/README.md`を参照）

## 使い方

各ディレクトリに移動し、`terraform init` → `terraform plan` → `terraform apply`の順に実行してください。
