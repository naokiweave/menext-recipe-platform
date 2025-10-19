# Docker 開発環境ガイド

Minextプラットフォームを Docker で実行するためのガイドです。

## 前提条件

- Docker Desktop がインストールされていること
  - Mac: [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)
  - Windows: [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
  - Linux: [Docker Engine](https://docs.docker.com/engine/install/)
- Docker Compose がインストールされていること（Docker Desktop には含まれています）

## クイックスタート

### 1. 環境変数の設定

`.env` ファイルを作成します：

```bash
cp .env.example .env
```

最低限必要な設定（ローカル開発の場合）:

```env
RACK_ENV=development
PORT=4567
```

AWS機能を使う場合は、追加で設定してください：

```env
AWS_REGION=ap-northeast-1
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_S3_BUCKET=your_bucket
```

### 2. コンテナの起動

```bash
# すべてのサービスを起動
docker-compose up

# バックグラウンドで起動
docker-compose up -d

# 特定のサービスのみ起動
docker-compose up web
```

初回起動時はイメージのビルドに数分かかります。

### 3. アプリケーションにアクセス

ブラウザで以下のURLを開きます：
- メイン画面: http://localhost:4567
- 管理画面: http://localhost:4567/admin

### 4. コンテナの停止

```bash
# コンテナを停止
docker-compose down

# コンテナとボリュームを削除（データも削除）
docker-compose down -v
```

## Docker Compose サービス構成

### web
- Sinatraアプリケーション
- ポート: 4567
- 開発時はコードの変更が自動反映されます

### db (PostgreSQL)
- データベース
- ポート: 5432
- ユーザー: minext
- パスワード: minext_password
- データベース: minext_production

### redis (オプション)
- セッション・キャッシュ管理
- ポート: 6379

### nginx (オプション)
- リバースプロキシ
- ポート: 80, 443

## よく使うコマンド

### コンテナの状態確認

```bash
# 実行中のコンテナを表示
docker-compose ps

# ログを表示
docker-compose logs

# 特定のサービスのログを表示
docker-compose logs web

# リアルタイムでログを追跡
docker-compose logs -f web
```

### コンテナに接続

```bash
# webコンテナに接続
docker-compose exec web bash

# データベースに接続
docker-compose exec db psql -U minext -d minext_production

# Redisに接続
docker-compose exec redis redis-cli
```

### データベース操作

```bash
# データベースマイグレーション
docker-compose exec web bundle exec rake db:migrate

# データベースのリセット
docker-compose exec web bundle exec rake db:reset

# シードデータの投入
docker-compose exec web bundle exec rake db:seed
```

### Bundler / Gem管理

```bash
# Gemのインストール
docker-compose exec web bundle install

# Gemの更新
docker-compose exec web bundle update

# 新しいGemを追加後、コンテナを再ビルド
docker-compose build web
docker-compose up -d web
```

### イメージの管理

```bash
# イメージをビルド
docker-compose build

# キャッシュなしでビルド
docker-compose build --no-cache

# 特定のサービスのみビルド
docker-compose build web
```

### データのクリーンアップ

```bash
# 停止中のコンテナを削除
docker-compose rm

# 未使用のイメージを削除
docker image prune

# 未使用のボリュームを削除
docker volume prune

# すべてをクリーンアップ
docker system prune -a
```

## 開発ワークフロー

### 通常の開発

1. コンテナを起動
   ```bash
   docker-compose up -d
   ```

2. コードを編集（ローカルで編集すると自動的にコンテナに反映）

3. ログを確認
   ```bash
   docker-compose logs -f web
   ```

4. 変更をテスト
   - ブラウザでアクセス: http://localhost:4567

5. 終了時にコンテナを停止
   ```bash
   docker-compose down
   ```

### Gemfileを変更した場合

```bash
# コンテナを再ビルド
docker-compose build web

# コンテナを再起動
docker-compose up -d web
```

### データベースの初期化

```bash
# データベースを作成
docker-compose exec web bundle exec rake db:create

# マイグレーション実行
docker-compose exec web bundle exec rake db:migrate

# シードデータ投入
docker-compose exec web bundle exec rake db:seed
```

## トラブルシューティング

### ポートが既に使用されている

エラー: `Bind for 0.0.0.0:4567 failed: port is already allocated`

```bash
# 使用中のプロセスを確認
lsof -i :4567

# プロセスを終了
kill -9 <PID>

# または、docker-compose.ymlでポートを変更
ports:
  - "4568:4567"
```

### コンテナが起動しない

```bash
# ログを確認
docker-compose logs web

# コンテナを再ビルド
docker-compose build --no-cache web
docker-compose up -d web
```

### データベースに接続できない

```bash
# データベースコンテナが起動しているか確認
docker-compose ps db

# データベースのヘルスチェック
docker-compose exec db pg_isready -U minext

# データベースを再起動
docker-compose restart db
```

### ボリュームの問題

```bash
# ボリュームを削除して再作成
docker-compose down -v
docker-compose up -d
```

### パーミッションエラー

```bash
# コンテナ内でオーナーを変更
docker-compose exec web chown -R nobody:nogroup /app
```

## 本番環境へのデプロイ

### Docker イメージのビルド

```bash
# 本番用イメージをビルド
docker build -t minext:latest .

# タグをつける
docker tag minext:latest your-registry/minext:latest

# レジストリにプッシュ
docker push your-registry/minext:latest
```

### AWS ECS へのデプロイ

1. ECR にイメージをプッシュ

```bash
# ECRにログイン
aws ecr get-login-password --region ap-northeast-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com

# イメージをタグ付け
docker tag minext:latest <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/minext:latest

# プッシュ
docker push <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/minext:latest
```

2. ECS タスク定義を作成
3. ECS サービスをデプロイ

詳細は `AWS_DEPLOYMENT.md` を参照してください。

## パフォーマンス最適化

### Mac/Windows での開発

Docker Desktop on Mac/Windows では、ボリュームマウントが遅い場合があります。

#### 解決策1: Cached/Delegated マウント

```yaml
volumes:
  - .:/app:cached
```

#### 解決策2: Named Volume を使用

```yaml
volumes:
  - bundle_cache:/usr/local/bundle
```

### イメージサイズの削減

Multi-stage build を使用することで、イメージサイズを削減しています。

```bash
# イメージサイズを確認
docker images minext
```

## セキュリティ

### ベストプラクティス

1. **非rootユーザーで実行**
   ```dockerfile
   USER nobody
   ```

2. **環境変数の管理**
   - `.env` ファイルは `.gitignore` に追加済み
   - 本番環境では環境変数を直接設定

3. **シークレットの管理**
   ```bash
   # Docker Secrets を使用（Swarm/Kubernetes）
   docker secret create db_password ./db_password.txt
   ```

4. **イメージのスキャン**
   ```bash
   # 脆弱性スキャン
   docker scan minext:latest
   ```

## モニタリング

### コンテナのリソース使用状況

```bash
# リアルタイムでリソース使用状況を表示
docker stats

# 特定のコンテナのみ
docker stats minext-web-1
```

### ヘルスチェック

すべてのサービスにヘルスチェックが設定されています：

```bash
# ヘルスステータスを確認
docker-compose ps
```

## 開発環境のカスタマイズ

### docker-compose.override.yml

個人用の設定を追加する場合：

```yaml
# docker-compose.override.yml
version: '3.8'

services:
  web:
    environment:
      - DEBUG=true
    ports:
      - "4568:4567"
```

このファイルは自動的に読み込まれ、`.gitignore` に追加されています。

## FAQ

### Q: ローカルのRubyとDockerのどちらを使うべきか？

**A**: Dockerの使用を推奨します。理由：
- 環境が統一される
- チーム開発がしやすい
- 本番環境と同じ環境でテストできる

### Q: データベースはSQLite3とPostgreSQLのどちらを使うべきか？

**A**: 開発環境では両方使えます：
- SQLite3: シンプル、設定不要
- PostgreSQL: 本番環境と同じ、機能豊富

本番環境ではPostgreSQLまたはAWS RDSを推奨。

### Q: Dockerコンテナが遅い

**A**:
1. Docker Desktop のリソース設定を確認（CPU, メモリ）
2. ボリュームマウントを `:cached` に変更
3. Named Volumes を使用

### Q: M1/M2 Mac で動作しますか？

**A**: はい、動作します。イメージは自動的に ARM64 用にビルドされます。

## 参考リンク

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Ruby on Docker](https://docs.docker.com/samples/ruby/)
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

## サポート

問題が発生した場合：
1. ログを確認: `docker-compose logs`
2. コンテナを再起動: `docker-compose restart`
3. イメージを再ビルド: `docker-compose build --no-cache`
4. すべてをクリーンアップ: `docker-compose down -v && docker-compose up -d`
