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

- **バックエンド**: Ruby 3.3.6 (Sinatra 3.2.0)
- **データベース**: SQLite3
- **認証**: BCrypt (セッションベース)
- **フロントエンド**: HTML/CSS/JavaScript (ERB)
- **Webサーバー**: Puma
- **デプロイ**: Railway/Docker対応

## ローカル開発

```bash
# 依存関係のインストール
bundle install

# サーバー起動
ruby server.rb

# アクセス
open http://localhost:4567
```

サーバーが起動すると以下のURLでアクセスできます:
- **トップページ**: http://localhost:4567
- **ログイン**: http://localhost:4567/login
- **サインアップ**: http://localhost:4567/signup
- **管理画面**: http://localhost:4567/admin
- **API**: http://localhost:4567/api/recipes

## API エンドポイント

### 認証
- `POST /api/auth/signup` - ユーザー登録
- `POST /api/auth/login` - ログイン
- `POST /api/auth/logout` - ログアウト
- `GET /api/auth/me` - 現在のユーザー情報取得

### レシピ
- `GET /api/recipes` - レシピ一覧（検索・フィルタリング機能付き）
- `GET /api/recipes/:id` - レシピ詳細
- `GET /api/recipes/popular` - 人気レシピ一覧

### ユーザーアクション
- `POST /api/recipes/:id/save` - レシピを保存
- `DELETE /api/recipes/:id/save` - レシピの保存を解除
- `POST /api/recipes/:id/rate` - レシピを評価
- `POST /api/recipes/:id/view` - 視聴記録を保存

### タグ
- `GET /api/tags` - タグ一覧
- `GET /api/tags/:id/recipes` - タグ別レシピ一覧

詳細なAPI仕様は [docs/BACKEND_API.md](docs/BACKEND_API.md) を参照してください。

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