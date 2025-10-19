# Minext プロジェクト用 Makefile

.PHONY: help setup up down build logs shell db-setup docker-dev docker-prod clean

# デフォルトターゲット
help:
	@echo "Minext プロジェクト コマンド一覧"
	@echo ""
	@echo "開発環境:"
	@echo "  make setup       - 初期セットアップ (.env作成、bundle install)"
	@echo "  make up          - Dockerコンテナを起動"
	@echo "  make down        - Dockerコンテナを停止"
	@echo "  make build       - Dockerイメージをビルド"
	@echo "  make logs        - ログを表示"
	@echo "  make shell       - webコンテナに接続"
	@echo ""
	@echo "データベース:"
	@echo "  make db-setup    - データベースのセットアップ"
	@echo "  make db-migrate  - マイグレーション実行"
	@echo "  make db-reset    - データベースをリセット"
	@echo ""
	@echo "その他:"
	@echo "  make clean       - 不要なファイルを削除"
	@echo "  make test        - テストを実行"

# 初期セットアップ
setup:
	@echo "=== 初期セットアップ ==="
	cp -n .env.example .env || true
	@echo ".env ファイルを作成しました（既に存在する場合はスキップ）"
	@echo "必要に応じて .env を編集してください"
	bundle install
	@echo "セットアップ完了！"

# Dockerコンテナ起動
up:
	docker-compose up -d
	@echo "コンテナを起動しました"
	@echo "アプリケーション: http://localhost:4567"

# 開発環境用（簡易版）
dev:
	docker-compose -f docker-compose.dev.yml up

# Dockerコンテナ停止
down:
	docker-compose down

# Dockerイメージビルド
build:
	docker-compose build

# ログ表示
logs:
	docker-compose logs -f web

# webコンテナに接続
shell:
	docker-compose exec web bash

# データベースセットアップ
db-setup:
	docker-compose exec web bundle exec rake db:create
	docker-compose exec web bundle exec rake db:migrate
	docker-compose exec web bundle exec rake db:seed

# マイグレーション
db-migrate:
	docker-compose exec web bundle exec rake db:migrate

# データベースリセット
db-reset:
	docker-compose exec web bundle exec rake db:reset

# テスト実行
test:
	docker-compose exec web bundle exec rspec

# クリーンアップ
clean:
	rm -rf tmp/*
	rm -rf log/*.log
	docker-compose down -v
	docker system prune -f

# 本番用イメージビルド
docker-prod:
	docker build -t minext:latest .
	@echo "本番用イメージをビルドしました: minext:latest"

# AWS ECRにプッシュ（要設定）
ecr-push:
	@echo "ECR リポジトリURLを設定してください"
	# aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com
	# docker tag minext:latest <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/minext:latest
	# docker push <account-id>.dkr.ecr.ap-northeast-1.amazonaws.com/minext:latest
