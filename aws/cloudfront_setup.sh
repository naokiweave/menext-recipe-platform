#!/bin/bash

# CloudFront設定スクリプト
# 使い方: ./aws/cloudfront_setup.sh <S3バケット名>

BUCKET_NAME=$1
REGION="ap-northeast-1"

if [ -z "$BUCKET_NAME" ]; then
  echo "エラー: S3バケット名を指定してください"
  echo "使い方: ./aws/cloudfront_setup.sh <S3バケット名>"
  exit 1
fi

echo "=== CloudFront ディストリビューション作成 ==="
echo "S3バケット: $BUCKET_NAME"

# OAI (Origin Access Identity) 作成
OAI_ID=$(aws cloudfront create-cloud-front-origin-access-identity \
  --cloud-front-origin-access-identity-config \
  CallerReference=$(date +%s),Comment="Minext Videos OAI" \
  --query 'CloudFrontOriginAccessIdentity.Id' \
  --output text)

echo "OAI作成完了: $OAI_ID"

# S3バケットポリシーを更新（CloudFrontからのアクセスのみ許可）
cat > /tmp/s3-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity $OAI_ID"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
    }
  ]
}
EOF

aws s3api put-bucket-policy \
  --bucket $BUCKET_NAME \
  --policy file:///tmp/s3-policy.json

# CloudFront設定JSONを作成
cat > /tmp/cloudfront-config.json <<EOF
{
  "CallerReference": "$(date +%s)",
  "Comment": "Minext Video Distribution",
  "Enabled": true,
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-$BUCKET_NAME",
        "DomainName": "$BUCKET_NAME.s3.$REGION.amazonaws.com",
        "S3OriginConfig": {
          "OriginAccessIdentity": "origin-access-identity/cloudfront/$OAI_ID"
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-$BUCKET_NAME",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "Compress": true,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      }
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    }
  },
  "PriceClass": "PriceClass_200"
}
EOF

# CloudFront ディストリビューション作成
DISTRIBUTION_ID=$(aws cloudfront create-distribution \
  --distribution-config file:///tmp/cloudfront-config.json \
  --query 'Distribution.Id' \
  --output text)

DOMAIN_NAME=$(aws cloudfront get-distribution \
  --id $DISTRIBUTION_ID \
  --query 'Distribution.DomainName' \
  --output text)

echo ""
echo "=== 完了 ==="
echo "CloudFront ディストリビューションが作成されました"
echo "Distribution ID: $DISTRIBUTION_ID"
echo "Domain Name: $DOMAIN_NAME"
echo ""
echo "次のステップ:"
echo "1. .env ファイルに以下を追加してください:"
echo "   AWS_CLOUDFRONT_DOMAIN=$DOMAIN_NAME"
echo "   AWS_CLOUDFRONT_DISTRIBUTION_ID=$DISTRIBUTION_ID"
echo ""
echo "注意: CloudFrontの設定が反映されるまで15-20分かかります"
