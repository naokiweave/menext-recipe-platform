#!/bin/bash

# S3バケット設定スクリプト
# 使い方: ./aws/s3_setup.sh <バケット名>

BUCKET_NAME=${1:-minext-videos-$(date +%s)}
REGION="ap-northeast-1"  # 東京リージョン

echo "=== S3バケット作成 ==="
echo "バケット名: $BUCKET_NAME"
echo "リージョン: $REGION"

# S3バケット作成
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $REGION \
  --create-bucket-configuration LocationConstraint=$REGION

# パブリックアクセスをブロック（CloudFront経由のみアクセス可能にする）
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# バージョニング有効化
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# CORS設定
aws s3api put-bucket-cors \
  --bucket $BUCKET_NAME \
  --cors-configuration file://aws/s3_cors.json

# ライフサイクルルール（古い動画の自動削除）
aws s3api put-bucket-lifecycle-configuration \
  --bucket $BUCKET_NAME \
  --lifecycle-configuration file://aws/s3_lifecycle.json

echo ""
echo "=== 完了 ==="
echo "S3バケットが作成されました: $BUCKET_NAME"
echo ""
echo "次のステップ:"
echo "1. .env ファイルに以下を追加してください:"
echo "   AWS_S3_BUCKET=$BUCKET_NAME"
echo "   AWS_REGION=$REGION"
echo ""
echo "2. CloudFront設定を実行してください:"
echo "   ./aws/cloudfront_setup.sh $BUCKET_NAME"