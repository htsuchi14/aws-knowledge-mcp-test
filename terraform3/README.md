# Terraform VPC/ALB/ECS/ECR/RDS インフラストラクチャ

このTerraform構成は、AWSでWebアプリケーション用の完全なインフラストラクチャを構築します。

## アーキテクチャ概要

- **VPC**: 複数AZにまたがるパブリック/プライベートサブネット
- **ALB**: インターネット向けApplication Load Balancer
- **ECS**: Fargateを使用したコンテナオーケストレーション
- **ECR**: Dockerイメージリポジトリ
- **RDS**: PostgreSQL 16データベース（プライベートサブネット配置）

## セキュリティ機能

- ✅ すべてのサブネットは複数AZに分散（高可用性）
- ✅ ECSタスクとRDSはプライベートサブネットに配置
- ✅ RDSは暗号化（KMS）とSSL接続強制
- ✅ ECRイメージは暗号化とスキャン有効化
- ✅ セキュリティグループは最小権限の原則に従う
- ✅ CloudWatch Logsは暗号化（KMS）
- ✅ DBパスワードはSecrets Managerで管理
- ✅ ALBアクセスログをS3に保存

## 前提条件

- Terraform 1.9以上
- AWS CLI設定済み
- AWSプロファイル `terraform-mcp-test` が設定済み

## 使用方法

### 1. 初期化

```bash
terraform init
```

### 2. プランの確認

```bash
terraform plan
```

### 3. インフラのデプロイ

```bash
terraform apply
```

### 4. コンテナイメージのプッシュ

```bash
# ECRログイン
aws ecr get-login-password --region ap-northeast-1 --profile terraform-mcp-test | \
  docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url | cut -d'/' -f1)

# イメージのビルドとプッシュ
docker build -t $(terraform output -raw ecr_repository_url):latest .
docker push $(terraform output -raw ecr_repository_url):latest
```

### 5. アプリケーションへのアクセス

```bash
echo "http://$(terraform output -raw alb_dns_name)"
```

## コスト最適化

- ECS Fargate Spotを使用可能（`ecs.tf`の容量プロバイダー設定）
- RDSは`db.t3.micro`インスタンス（本番環境では適切なサイズに変更）
- NATゲートウェイは各AZに配置（コスト削減のため1つに減らすことも可能）

## カスタマイズ

`variables.tf`で以下をカスタマイズ可能:

- `aws_region`: AWSリージョン
- `environment`: 環境名
- `vpc_cidr`: VPC CIDRブロック
- `app_count`: ECSタスク数
- `container_port`: コンテナポート

## リソース削除

```bash
terraform destroy
```

## 注意事項

- 本番環境では以下を推奨:
  - RDSのマルチAZ有効化
  - ALBでACM証明書を使用したHTTPS化
  - RDS deletion_protection有効化
  - より大きなインスタンスタイプ
  - バックアップ保持期間の延長

## トラブルシューティング

### `terraform apply`でECRリポジトリが見つからない場合

ECSタスク定義内のECRリポジトリ参照は、`terraform apply`後に出力される
`ecr_repository_url`を使って更新してください。ECRへのログインと
イメージプッシュが完了していない場合は、デプロイが失敗します。

### ALBのヘルスチェックが失敗する場合

- コンテナポートと`container_port`変数が一致しているか確認してください。
- セキュリティグループのALB→ECS通信が許可されているか確認してください。
