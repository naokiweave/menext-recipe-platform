# ミーネクスト - 動画レシピプラットフォーム

業務効率化のための実践的な動画レシピプラットフォームです。

## 機能

- 📚 動画レシピの一覧表示
- 🎥 動画プレイヤー（HLS配信対応予定）
- 🏷️ 業種・用途・難易度での検索
- 🔒 無料・プレミアムアクセス制御
- ⚙️ 管理画面
- 🔌 REST API

## 技術スタック

- **バックエンド**: Ruby (Sinatra)
- **データベース**: SQLite3
- **フロントエンド**: HTML/CSS/JavaScript (ERB)
- **デプロイ**: Heroku/Railway対応

## ローカル開発

```bash
# 依存関係のインストール
bundle install

# サーバー起動
ruby simple_server.rb

# アクセス
open http://localhost:4567
```

## API エンドポイント

- `GET /api/recipes` - レシピ一覧
- `GET /api/recipes/:id` - レシピ詳細

## デプロイ

### Heroku
```bash
git push heroku main
```

### Railway
```bash
railway deploy
```

## 今後の実装予定

- [ ] HLS動画配信
- [ ] FFmpegによる動画変換
- [ ] S3 + CloudFront配信
- [ ] AI連携（レシピ自動生成）
- [ ] ユーザー認証
- [ ] 決済機能（Stripe）

## ライセンス

MIT License