# AWS デプロイ手順書

Minextプラットフォームを AWS 上にデプロイする手順です。

## 前提条件

- AWS アカウントを持っていること
- AWS CLI がインストールされていること
- AWS 認証情報が設定されていること (`aws configure`)
- EB CLI がインストールされていること (`pip install awsebcli`)

## デプロイ手順

### 1. AWS認証情報の設定

```bash
aws configure
```

以下の情報を入力してください：
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `ap-northeast-1` (東京)
- Default output format: `json`

### 2. S3バケットの作成

動画ストレージ用のS3バケットを作成します。

```bash
./aws/s3_setup.sh minext-videos-YOUR_NAME
```

作成されたバケット名をメモしてください。

### 3. CloudFront ディストリビューションの作成

CDN配信用のCloudFrontを設定します。

```bash
./aws/cloudfront_setup.sh minext-videos-YOUR_NAME
```

作成されたCloudFront URLをメモしてください。
**注意**: CloudFrontの設定が反映されるまで15-20分かかります。

### 4. 環境変数の設定

`.env` ファイルを作成します。

```bash
cp .env.example .env
```

`.env` ファイルを編集して、以下の値を設定してください：

```env
# AWS設定
AWS_REGION=ap-northeast-1
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here

# S3設定
AWS_S3_BUCKET=minext-videos-YOUR_NAME
AWS_S3_REGION=ap-northeast-1

# CloudFront設定
AWS_CLOUDFRONT_DOMAIN=xxxxx.cloudfront.net
AWS_CLOUDFRONT_DISTRIBUTION_ID=EXXXXXXXXX

# その他の設定
RACK_ENV=production
SECRET_KEY_BASE=$(openssl rand -hex 64)
```

### 5. Elastic Beanstalk アプリケーションの初期化

```bash
eb init
```

以下を選択してください：
- Region: `ap-northeast-1` (東京)
- Application name: `minext`
- Platform: `Ruby 3.3 running on 64bit Amazon Linux 2023`
- SSH: Yes (トラブルシューティング用)

### 6. Elastic Beanstalk 環境の作成

```bash
eb create minext-production
```

環境設定：
- Environment name: `minext-production`
- DNS CNAME prefix: `minext-production` (または任意)
- Load balancer type: `application`

### 7. 環境変数の設定

Elastic Beanstalk環境に環境変数を設定します。

```bash
eb setenv \
  AWS_REGION=ap-northeast-1 \
  AWS_ACCESS_KEY_ID=your_access_key_here \
  AWS_SECRET_ACCESS_KEY=your_secret_key_here \
  AWS_S3_BUCKET=minext-videos-YOUR_NAME \
  AWS_CLOUDFRONT_DOMAIN=xxxxx.cloudfront.net \
  RACK_ENV=production \
  SECRET_KEY_BASE=your_secret_key_here
```

### 8. デプロイ

```bash
eb deploy
```

### 9. アプリケーションを開く

```bash
eb open
```

ブラウザで自動的にアプリケーションが開きます。

## 更新のデプロイ

コードを更新した場合：

```bash
git add .
git commit -m "Update message"
eb deploy
```

## ログの確認

```bash
# 最新のログを表示
eb logs

# リアルタイムでログを追跡
eb logs --stream
```

## データベースの設定（オプション）

SQLite3の代わりにRDSを使用する場合：

### RDSインスタンスの作成

```bash
aws rds create-db-instance \
  --db-instance-identifier minext-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username minext_admin \
  --master-user-password YOUR_PASSWORD \
  --allocated-storage 20 \
  --vpc-security-group-ids sg-xxxxxx \
  --db-subnet-group-name default \
  --backup-retention-period 7 \
  --region ap-northeast-1
```

### 環境変数の追加

```bash
eb setenv DATABASE_URL=postgresql://username:password@host:5432/database_name
```

## コスト最適化

### 無料枠での運用

- **EC2**: t3.micro (月750時間無料)
- **S3**: 5GB ストレージ、20,000 GETリクエスト/月
- **CloudFront**: 50GB データ転送/月
- **RDS**: db.t3.micro (月750時間無料、20GB ストレージ)

### 開発環境の停止

使っていない時は環境を停止してコストを節約：

```bash
# 環境を停止
eb stop minext-production

# 環境を再開
eb start minext-production
```

## トラブルシューティング

### デプロイが失敗する

```bash
# ログを確認
eb logs

# SSH接続してサーバーを確認
eb ssh
```

### 動画がアップロードできない

1. S3バケットのCORS設定を確認
2. IAMロールの権限を確認
3. Nginxの `client_max_body_size` 設定を確認

### CloudFrontで動画が表示されない

1. CloudFront設定が反映されるまで15-20分待つ
2. キャッシュをクリア: `aws cloudfront create-invalidation --distribution-id EXXXXXXXXX --paths "/*"`

## セキュリティ設定

### HTTPSの設定

1. AWS Certificate Manager (ACM) で証明書を取得
2. Elastic Beanstalk環境でHTTPSリスナーを設定
3. ロードバランサーに証明書を関連付け

```bash
eb config
```

### セキュリティグループの設定

必要なポートのみ開放：
- HTTP: 80
- HTTPS: 443
- SSH: 22 (開発時のみ)

## モニタリング

### CloudWatch

Elastic Beanstalkは自動的にCloudWatchでメトリクスを収集します：

```bash
# メトリクスを確認
eb health
eb status
```

### アラームの設定

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name minext-high-cpu \
  --alarm-description "CPU使用率が80%を超えた" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold
```

## バックアップ

### S3バケットのバックアップ

バージョニングが有効になっているため、削除されたファイルも復元できます。

### データベースのバックアップ（RDS使用時）

RDSは自動的に毎日バックアップを作成します（保持期間: 7日）。

手動スナップショットを作成：

```bash
aws rds create-db-snapshot \
  --db-instance-identifier minext-db \
  --db-snapshot-identifier minext-db-snapshot-$(date +%Y%m%d)
```

## スケーリング

### 自動スケーリングの設定

```bash
eb scale 2  # インスタンス数を2に増やす
```

### オートスケーリングの設定

`.ebextensions/autoscaling.config` を作成：

```yaml
option_settings:
  aws:autoscaling:asg:
    MinSize: 1
    MaxSize: 4
  aws:autoscaling:trigger:
    MeasureName: CPUUtilization
    Statistic: Average
    Unit: Percent
    UpperThreshold: 80
    LowerThreshold: 20
```

## クリーンアップ

環境を削除する場合：

```bash
# 環境を削除
eb terminate minext-production

# S3バケットを削除
aws s3 rb s3://minext-videos-YOUR_NAME --force

# CloudFrontディストリビューションを削除
aws cloudfront delete-distribution --id EXXXXXXXXX --if-match ETAG
```

## 参考リンク

- [AWS Elastic Beanstalk ドキュメント](https://docs.aws.amazon.com/elasticbeanstalk/)
- [AWS S3 ドキュメント](https://docs.aws.amazon.com/s3/)
- [AWS CloudFront ドキュメント](https://docs.aws.amazon.com/cloudfront/)
- [EB CLI コマンドリファレンス](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3.html)

## サポート

問題が発生した場合は、以下を確認してください：
1. AWS ログ (`eb logs`)
2. アプリケーションログ
3. CloudWatch メトリクス
4. セキュリティグループとIAMロールの設定
