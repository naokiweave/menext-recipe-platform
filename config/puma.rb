# Puma設定ファイル

# ワーカー数（本番環境では2-4推奨）
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# スレッド数
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# ポート設定
port ENV.fetch("PORT") { 4567 }

# 環境
environment ENV.fetch("RACK_ENV") { "development" }

# プリロード（メモリ節約）
preload_app!

# PIDファイル
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# ワーカーのタイムアウト
worker_timeout 30

# ワーカー起動時の処理
on_worker_boot do
  # データベース接続があればここで再接続
end

# クリーンシャットダウン
on_restart do
  puts 'Refreshing Gemfile'
  ENV["BUNDLE_GEMFILE"] = ""
end