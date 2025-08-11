#!/usr/bin/env ruby

require 'bundler/setup'
require 'sinatra'
require 'sqlite3'
require 'json'

# データベース初期化
def init_database
  db = SQLite3::Database.new 'db/simple.sqlite3'
  
  # テーブル作成
  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS recipes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      video_url TEXT,
      thumbnail_url TEXT,
      industry TEXT NOT NULL,
      purpose TEXT NOT NULL,
      difficulty_level TEXT NOT NULL,
      duration_minutes INTEGER NOT NULL,
      access_level TEXT DEFAULT 'free',
      preview_seconds INTEGER,
      ingredients TEXT,
      instructions TEXT,
      tips TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  SQL
  
  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS tags (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  SQL
  
  # サンプルデータ挿入
  sample_recipes = [
    {
      title: 'Excelでの売上データ分析の基本',
      description: '営業チームの売上データを効率的に分析し、視覚的なグラフで表現する方法を学びます。',
      industry: '営業・販売',
      purpose: 'データ分析',
      difficulty_level: '初級',
      duration_minutes: 15,
      access_level: 'free',
      ingredients: '<ul><li>Excel 2019以降</li><li>売上データ（CSV形式）</li><li>グラフ作成用テンプレート</li></ul>',
      instructions: '<ol><li>データの読み込み</li><li>ピボットテーブルの作成</li><li>グラフの挿入と書式設定</li><li>レポートの完成</li></ol>',
      tips: '<p>データの前処理が重要です。空白セルや不正な値がないか事前にチェックしましょう。</p>',
      video_url: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4'
    },
    {
      title: 'PowerPointで魅力的な企画書を作る',
      description: '上司や顧客に響く企画書の構成とデザインのコツを実践的に解説します。',
      industry: '企画・マーケティング',
      purpose: '資料作成',
      difficulty_level: '中級',
      duration_minutes: 25,
      access_level: 'premium',
      preview_seconds: 60,
      ingredients: '<ul><li>PowerPoint 2019以降</li><li>企画書テンプレート</li><li>画像素材</li></ul>',
      instructions: '<ol><li>構成の設計</li><li>スライドマスターの設定</li><li>コンテンツの作成</li><li>アニメーションの追加</li></ol>',
      tips: '<p>1スライド1メッセージを心がけ、文字は最小限に抑えましょう。</p>',
      video_url: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4'
    }
  ]
  
  sample_recipes.each do |recipe|
    db.execute(
      "INSERT OR IGNORE INTO recipes (title, description, industry, purpose, difficulty_level, duration_minutes, access_level, preview_seconds, ingredients, instructions, tips, video_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      [recipe[:title], recipe[:description], recipe[:industry], recipe[:purpose], recipe[:difficulty_level], recipe[:duration_minutes], recipe[:access_level], recipe[:preview_seconds], recipe[:ingredients], recipe[:instructions], recipe[:tips], recipe[:video_url]]
    )
  end
  
  db.close
end

# データベース初期化
init_database

# Sinatraアプリケーション
set :port, ENV['PORT'] || 4567
set :bind, '0.0.0.0'

# 静的ファイル配信
set :public_folder, 'public'
set :static, true

# MIME type設定
mime_type :mp4, 'video/mp4'
mime_type :webm, 'video/webm'
mime_type :m3u8, 'application/vnd.apple.mpegurl'
mime_type :ts, 'video/mp2t'

# ルート
get '/' do
  db = SQLite3::Database.new 'db/simple.sqlite3'
  db.results_as_hash = true
  recipes = db.execute("SELECT * FROM recipes ORDER BY created_at DESC")
  db.close
  
  erb :index, locals: { recipes: recipes }
end

get '/recipes/:id' do
  db = SQLite3::Database.new 'db/simple.sqlite3'
  db.results_as_hash = true
  recipe = db.execute("SELECT * FROM recipes WHERE id = ?", [params[:id]]).first
  db.close
  
  if recipe
    erb :recipe_detail, locals: { recipe: recipe }
  else
    status 404
    "Recipe not found"
  end
end

get '/admin' do
  db = SQLite3::Database.new 'db/simple.sqlite3'
  db.results_as_hash = true
  recipes = db.execute("SELECT * FROM recipes ORDER BY created_at DESC")
  db.close
  
  erb :admin, locals: { recipes: recipes }
end

# API エンドポイント
get '/api/recipes' do
  content_type :json
  
  db = SQLite3::Database.new 'db/simple.sqlite3'
  db.results_as_hash = true
  recipes = db.execute("SELECT * FROM recipes ORDER BY created_at DESC")
  db.close
  
  { recipes: recipes }.to_json
end

get '/api/recipes/:id' do
  content_type :json
  
  db = SQLite3::Database.new 'db/simple.sqlite3'
  db.results_as_hash = true
  recipe = db.execute("SELECT * FROM recipes WHERE id = ?", [params[:id]]).first
  db.close
  
  if recipe
    { recipe: recipe }.to_json
  else
    status 404
    { error: "Recipe not found" }.to_json
  end
end

port = ENV['PORT'] || 4567
puts "Server starting on http://localhost:#{port}"
puts "Admin panel: http://localhost:#{port}/admin"
puts "API: http://localhost:#{port}/api/recipes"