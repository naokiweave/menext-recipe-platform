# ミーネクスト - バックエンドAPI仕様書

## 概要

ミーネクストのバックエンドAPIは、Rubyの軽量フレームワークSinatraで構築されています。
RESTful APIの設計原則に従い、JSON形式でデータをやり取りします。

## ベースURL

```
http://localhost:4567
```

---

## 認証

### POST /api/auth/signup

ユーザー登録

**リクエスト**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "山田太郎"
}
```

**レスポンス (201 Created)**
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "山田太郎",
    "subscription_level": "free",
    "created_at": "2025-01-28T10:00:00"
  },
  "message": "アカウントが作成されました"
}
```

### POST /api/auth/login

ログイン

**リクエスト**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**レスポンス (200 OK)**
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "山田太郎",
    "subscription_level": "free"
  },
  "message": "ログインしました"
}
```

**エラーレスポンス (401 Unauthorized)**
```json
{
  "error": "メールアドレスまたはパスワードが正しくありません"
}
```

### POST /api/auth/logout

ログアウト

**レスポンス (200 OK)**
```json
{
  "message": "ログアウトしました"
}
```

### GET /api/auth/me

現在のユーザー情報取得

**レスポンス (200 OK)**
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "山田太郎",
    "subscription_level": "free"
  }
}
```

---

## レシピ

### GET /api/recipes

レシピ一覧取得（検索・フィルタリング機能付き）

**クエリパラメータ**
- `q` (string, optional): 検索キーワード（タイトル・説明文を検索）
- `industry` (string, optional): 業種フィルタ
- `difficulty` (string, optional): 難易度フィルタ（初級/中級/上級）
- `access_level` (string, optional): アクセスレベル（free/premium）
- `limit` (integer, optional): 取得件数（デフォルト: 20）
- `offset` (integer, optional): オフセット（デフォルト: 0）

**レスポンス (200 OK)**
```json
{
  "recipes": [
    {
      "id": 1,
      "title": "新人も理解が深まる！作業手順書のマンガ化",
      "description": "複雑な作業手順を、誰でも直感的に理解できるマンガ形式に変換します。",
      "video_url": "/videos/225..mp4",
      "thumbnail_url": "/thumbnails/225.jpg",
      "industry": "製造・現場",
      "purpose": "教育・トレーニング",
      "difficulty_level": "初級",
      "duration_minutes": 1,
      "access_level": "free",
      "view_count": 150,
      "save_count": 25,
      "rating_average": 4.5,
      "rating_count": 10,
      "created_at": "2025-01-28T10:00:00"
    }
  ],
  "total": 1,
  "limit": 20,
  "offset": 0
}
```

**使用例**
```bash
# 全レシピ取得
curl http://localhost:4567/api/recipes

# キーワード検索
curl "http://localhost:4567/api/recipes?q=ChatGPT"

# 業種フィルタ
curl "http://localhost:4567/api/recipes?industry=製造・現場"

# 難易度フィルタ
curl "http://localhost:4567/api/recipes?difficulty=初級"

# 複合検索
curl "http://localhost:4567/api/recipes?q=マンガ&industry=製造・現場&difficulty=初級"

# ページネーション
curl "http://localhost:4567/api/recipes?limit=10&offset=20"
```

### GET /api/recipes/:id

レシピ詳細取得

**レスポンス (200 OK)**
```json
{
  "recipe": {
    "id": 1,
    "title": "新人も理解が深まる！作業手順書のマンガ化",
    "description": "複雑な作業手順を、誰でも直感的に理解できるマンガ形式に変換します。",
    "video_url": "/videos/225..mp4",
    "thumbnail_url": "/thumbnails/225.jpg",
    "industry": "製造・現場",
    "purpose": "教育・トレーニング",
    "difficulty_level": "初級",
    "duration_minutes": 1,
    "access_level": "free",
    "view_count": 150,
    "save_count": 25,
    "rating_average": 4.5,
    "rating_count": 10
  },
  "steps": [
    {
      "id": 1,
      "recipe_id": 1,
      "step_number": 1,
      "title": "ChatGPTに画像をアップロードする",
      "description": "用意した手順書の画像をChatGPTにアップロードします。",
      "image_url": "/thumbnails/step_1.jpg",
      "prompt_example": "この作業手順書をマンガ形式に変換してください。",
      "technique_note": null
    }
  ],
  "tags": [
    {
      "id": 1,
      "name": "製造・現場職場",
      "category": "general"
    }
  ]
}
```

**エラーレスポンス (404 Not Found)**
```json
{
  "error": "Recipe not found"
}
```

### GET /api/recipes/popular

人気レシピ一覧取得

**クエリパラメータ**
- `limit` (integer, optional): 取得件数（デフォルト: 10）

**レスポンス (200 OK)**
```json
{
  "recipes": [
    {
      "id": 1,
      "title": "新人も理解が深まる！作業手順書のマンガ化",
      "view_count": 2400,
      "rating_average": 5.0,
      ...
    }
  ]
}
```

---

## ユーザーアクション

### POST /api/recipes/:id/save

レシピを保存（要認証）

**レスポンス (200 OK)**
```json
{
  "message": "レシピを保存しました",
  "action": {
    "id": 1,
    "user_id": 1,
    "recipe_id": 1,
    "action_type": "save",
    "created_at": "2025-01-28T10:00:00"
  }
}
```

**エラーレスポンス (401 Unauthorized)**
```json
{
  "error": "ログインが必要です"
}
```

### DELETE /api/recipes/:id/save

レシピの保存を解除（要認証）

**レスポンス (200 OK)**
```json
{
  "message": "レシピの保存を解除しました"
}
```

### POST /api/recipes/:id/rate

レシピを評価（要認証）

**リクエスト**
```json
{
  "rating": 5,
  "comment": "とても分かりやすかったです！"
}
```

**レスポンス (200 OK)**
```json
{
  "message": "レシピを評価しました",
  "action": {
    "id": 1,
    "user_id": 1,
    "recipe_id": 1,
    "action_type": "rate",
    "rating": 5,
    "comment": "とても分かりやすかったです！"
  }
}
```

**エラーレスポンス (400 Bad Request)**
```json
{
  "error": "評価は1-5の範囲で指定してください"
}
```

### POST /api/recipes/:id/view

視聴記録を保存（要認証）

**リクエスト**
```json
{
  "progress_seconds": 45
}
```

**レスポンス (200 OK)**
```json
{
  "message": "視聴記録を保存しました",
  "action": {
    "id": 1,
    "user_id": 1,
    "recipe_id": 1,
    "action_type": "view",
    "progress_seconds": 45
  }
}
```

---

## タグ

### GET /api/tags

タグ一覧取得

**レスポンス (200 OK)**
```json
{
  "tags": [
    {
      "id": 1,
      "name": "製造・現場職場",
      "category": "general"
    },
    {
      "id": 2,
      "name": "ChatGPT",
      "category": "general"
    }
  ]
}
```

### GET /api/tags/:id/recipes

タグ別レシピ一覧取得

**レスポンス (200 OK)**
```json
{
  "tag": {
    "id": 1,
    "name": "製造・現場職場",
    "category": "general"
  },
  "recipes": [
    {
      "id": 1,
      "title": "新人も理解が深まる！作業手順書のマンガ化",
      ...
    }
  ]
}
```

---

## エラーレスポンス

### 認証エラー (401 Unauthorized)
```json
{
  "error": "ログインが必要です"
}
```

### リソース未検出 (404 Not Found)
```json
{
  "error": "Recipe not found"
}
```

### バリデーションエラー (400 Bad Request)
```json
{
  "error": "評価は1-5の範囲で指定してください"
}
```

### サーバーエラー (500 Internal Server Error)
```json
{
  "error": "Internal server error"
}
```

---

## データモデル

### Recipe（レシピ）
```ruby
{
  id: integer,
  title: string,
  description: text,
  video_url: string,
  thumbnail_url: string,
  industry: string,
  purpose: string,
  difficulty_level: string,  # '初級', '中級', '上級'
  duration_minutes: integer,
  access_level: string,       # 'free', 'premium'
  view_count: integer,
  save_count: integer,
  rating_average: float,
  rating_count: integer,
  created_at: datetime
}
```

### RecipeStep（レシピ手順）
```ruby
{
  id: integer,
  recipe_id: integer,
  step_number: integer,
  title: string,
  description: text,
  image_url: string,
  prompt_example: text,
  technique_note: text
}
```

### User（ユーザー）
```ruby
{
  id: integer,
  email: string,
  name: string,
  subscription_level: string,  # 'free', 'premium'
  subscription_expires_at: datetime,
  created_at: datetime
}
```

### UserAction（ユーザーアクション）
```ruby
{
  id: integer,
  user_id: integer,
  recipe_id: integer,
  action_type: string,  # 'view', 'save', 'rate', 'comment'
  rating: integer,      # 1-5
  comment: text,
  progress_seconds: integer,
  created_at: datetime
}
```

### Tag（タグ）
```ruby
{
  id: integer,
  name: string,
  category: string,
  created_at: datetime
}
```

---

## 認証方式

現在はセッションベースの認証を使用しています。

1. `/api/auth/login` でログイン
2. セッションCookieが発行される
3. 以降のリクエストで自動的にセッションが維持される
4. `/api/auth/logout` でログアウト

**今後の実装予定:**
- JWT（JSON Web Token）による認証
- OAuth2.0対応（Google, Facebook等）
- APIキー認証

---

## レート制限

**現在:** 制限なし

**今後の実装予定:**
- 1分あたり60リクエスト（無料ユーザー）
- 1分あたり300リクエスト（プレミアムユーザー）

---

## CORS設定

開発環境では全てのオリジンからのアクセスを許可しています。

本番環境では特定のドメインのみ許可する予定です。

---

## テスト用のcURLコマンド例

```bash
# ユーザー登録
curl -X POST http://localhost:4567/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","name":"テストユーザー"}'

# ログイン
curl -X POST http://localhost:4567/api/auth/login \
  -H "Content-Type: application/json" \
  -c cookies.txt \
  -d '{"email":"test@example.com","password":"password123"}'

# レシピ一覧取得
curl http://localhost:4567/api/recipes

# レシピ詳細取得
curl http://localhost:4567/api/recipes/1

# レシピを保存（要ログイン）
curl -X POST http://localhost:4567/api/recipes/1/save \
  -b cookies.txt

# レシピを評価（要ログイン）
curl -X POST http://localhost:4567/api/recipes/1/rate \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{"rating":5,"comment":"とても良かったです！"}'

# ログアウト
curl -X POST http://localhost:4567/api/auth/logout \
  -b cookies.txt
```

---

## サーバー起動方法

```bash
# 依存関係のインストール
bundle install

# サーバー起動
ruby server.rb
```

サーバーが起動すると以下のURLでアクセスできます:
- トップページ: http://localhost:4567
- ログイン: http://localhost:4567/login
- サインアップ: http://localhost:4567/signup
- 管理画面: http://localhost:4567/admin
- API: http://localhost:4567/api/recipes

---

**最終更新**: 2025-01-28
**バージョン**: 1.0.0
