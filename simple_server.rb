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
  
  db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS recipe_steps (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recipe_id INTEGER NOT NULL,
      step_number INTEGER NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      image_url TEXT,
      video_timestamp INTEGER,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (recipe_id) REFERENCES recipes (id)
    )
  SQL
  
  # サンプルデータ挿入
  sample_recipes = [
    {
      title: '待望のGPT-5！エージェントでメール自動返信',
      description: 'GPT-5の新機能を活用して、メールの自動返信システムを構築する方法を学びます。',
      industry: 'IT・システム',
      purpose: 'AI活用',
      difficulty_level: '中級',
      duration_minutes: 16,
      access_level: 'free',
      ingredients: '<ul><li>ChatGPT Plus アカウント</li><li>Gmail または Outlook</li><li>Zapier アカウント</li><li>基本的なプログラミング知識</li></ul>',
      instructions: '<ol><li>GPT-5 エージェント機能の設定</li><li>メールフィルタリングルールの作成</li><li>自動返信テンプレートの設計</li><li>Zapier との連携設定</li><li>テスト実行と調整</li></ol>',
      tips: '<p>返信内容は簡潔で丁寧に。重要なメールは手動確認を推奨。定期的にログを確認して精度向上を図りましょう。</p>',
      video_url: '/videos/225..mp4',
      thumbnail_url: '/thumbnails/225.jpg',
      steps: [
        {
          title: 'ChatGPTに画像をアップロードする',
          description: '用意した画像をChatGPTにアップロードします。これで画像内の文字情報もとに自然が理解されるようになります。',
          image_url: '/thumbnails/step_1.jpg',
          video_timestamp: 30
        },
        {
          title: '文字起こしを依頼する',
          description: '画像内の文字を、画像の文字をそのまま文字化する5分間です。画像に書かれた内容が、テキストとして確認できるようになります。',
          image_url: '/thumbnails/step_2.jpg',
          video_timestamp: 120
        },
        {
          title: '共有用メッセージを整える',
          description: '読みやすい内容。LINE WORKSでそのまま送れる形式で共有文に変更しましょう。現場メンバーへの伝わりやすさを重視して作成します。',
          image_url: '/thumbnails/step_3.jpg',
          video_timestamp: 240
        }
      ]
    },
    {
      title: 'もう読めないとは言わせない！手書きメモの文字起こし',
      description: '手書きのメモや文書をデジタル化し、検索可能なテキストに変換する方法を学びます。',
      industry: '総務・人事',
      purpose: '文書作成',
      difficulty_level: '初級',
      duration_minutes: 12,
      access_level: 'free',
      ingredients: '<ul><li>スマートフォンまたはタブレット</li><li>OCRアプリ</li><li>クラウドストレージ</li></ul>',
      instructions: '<ol><li>手書きメモの撮影</li><li>OCRアプリでの文字認識</li><li>テキストの校正</li><li>クラウドへの保存</li></ol>',
      tips: '<p>撮影時は明るい場所で、文字がはっきり見えるように撮影しましょう。</p>',
      video_url: '/videos/recipe_2.mp4',
      thumbnail_url: '/thumbnails/recipe_2.svg'
    },
    {
      title: '会話しながら整理！音声モードで新規事業の壁打ち',
      description: 'ChatGPTの音声機能を使って、新規事業のアイデアを整理・発展させる手法を学びます。',
      industry: '企画・マーケティング',
      purpose: 'アイデア発想',
      difficulty_level: '中級',
      duration_minutes: 25,
      access_level: 'premium',
      preview_seconds: 60,
      ingredients: '<ul><li>ChatGPT Plus アカウント</li><li>スマートフォン</li><li>静かな環境</li></ul>',
      instructions: '<ol><li>音声モードの設定</li><li>事業アイデアの概要説明</li><li>対話形式での深掘り</li><li>アイデアの整理と記録</li></ol>',
      tips: '<p>自然な会話を心がけ、思いついたことは遠慮なく話してみましょう。</p>',
      video_url: '/videos/recipe_3.mp4',
      thumbnail_url: '/thumbnails/recipe_3.svg'
    },
    {
      title: '写真がピックリマン風に!? 思い出の写真でステッカー作成',
      description: '思い出の写真をピックリマン風のステッカーに変換し、オリジナルグッズを作成する方法。',
      industry: 'デザイン・クリエイティブ',
      purpose: '画像加工',
      difficulty_level: '初級',
      duration_minutes: 18,
      access_level: 'free',
      ingredients: '<ul><li>写真データ</li><li>画像編集アプリ</li><li>プリンター</li><li>ステッカー用紙</li></ul>',
      instructions: '<ol><li>写真の選択と準備</li><li>ピックリマン風エフェクトの適用</li><li>テキストやフレームの追加</li><li>印刷とカット</li></ol>',
      tips: '<p>明るくはっきりした写真を選ぶと、より良い仕上がりになります。</p>',
      video_url: '/videos/recipe_4.mp4',
      thumbnail_url: '/thumbnails/recipe_4.svg'
    }
  ]
  
  sample_recipes.each_with_index do |recipe, index|
    recipe_id = index + 1
    
    db.execute(
      "INSERT OR IGNORE INTO recipes (id, title, description, industry, purpose, difficulty_level, duration_minutes, access_level, preview_seconds, ingredients, instructions, tips, video_url, thumbnail_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      [recipe_id, recipe[:title], recipe[:description], recipe[:industry], recipe[:purpose], recipe[:difficulty_level], recipe[:duration_minutes], recipe[:access_level], recipe[:preview_seconds], recipe[:ingredients], recipe[:instructions], recipe[:tips], recipe[:video_url], recipe[:thumbnail_url]]
    )
    
    # 手順データの挿入（重複チェック付き）
    recipe[:steps]&.each_with_index do |step, step_index|
      # 既存の手順データがあるかチェック
      existing_step = db.execute("SELECT id FROM recipe_steps WHERE recipe_id = ? AND step_number = ?", [recipe_id, step_index + 1]).first
      unless existing_step
        db.execute(
          "INSERT INTO recipe_steps (recipe_id, step_number, title, description, image_url, video_timestamp) VALUES (?, ?, ?, ?, ?, ?)",
          [recipe_id, step_index + 1, step[:title], step[:description], step[:image_url], step[:video_timestamp]]
        )
      end
    end
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
  
  @recipe = db.execute("SELECT * FROM recipes WHERE id = ?", [params[:id]]).first
  @steps = db.execute("SELECT * FROM recipe_steps WHERE recipe_id = ? ORDER BY step_number", [params[:id]])
  
  db.close
  
  erb :recipe_detail
end

# 新規レシピ作成フォーム
get '/recipes/new' do
  erb :recipe_form
end

# レシピ編集フォーム
get '/recipes/:id/edit' do
  db = SQLite3::Database.new 'db/simple.sqlite3'
  db.results_as_hash = true
  
  @recipe = db.execute("SELECT * FROM recipes WHERE id = ?", [params[:id]]).first
  @steps = db.execute("SELECT * FROM recipe_steps WHERE recipe_id = ? ORDER BY step_number", [params[:id]])
  
  db.close
  
  if @recipe
    erb :recipe_form
  else
    status 404
    "Recipe not found"
  end
end

# レシピ作成
post '/recipes' do
  # ファイルアップロード処理
  video_url = nil
  thumbnail_url = nil
  
  if params[:video_file] && params[:video_file][:tempfile]
    video_filename = "recipe_#{Time.now.to_i}_#{params[:video_file][:filename]}"
    video_path = "public/videos/#{video_filename}"
    File.open(video_path, 'wb') { |f| f.write(params[:video_file][:tempfile].read) }
    video_url = "/videos/#{video_filename}"
  end
  
  if params[:thumbnail_file] && params[:thumbnail_file][:tempfile]
    thumbnail_filename = "thumb_#{Time.now.to_i}_#{params[:thumbnail_file][:filename]}"
    thumbnail_path = "public/thumbnails/#{thumbnail_filename}"
    File.open(thumbnail_path, 'wb') { |f| f.write(params[:thumbnail_file][:tempfile].read) }
    thumbnail_url = "/thumbnails/#{thumbnail_filename}"
  end
  
  db = SQLite3::Database.new 'db/simple.sqlite3'
  
  # レシピを挿入
  recipe_id = db.execute(
    "INSERT INTO recipes (title, description, industry, purpose, difficulty_level, duration_minutes, access_level, preview_seconds, ingredients, instructions, tips, video_url, thumbnail_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING id",
    [params[:title], params[:description], params[:industry], params[:purpose], params[:difficulty_level], params[:duration_minutes], params[:access_level], params[:preview_seconds], params[:ingredients], params[:instructions], params[:tips], video_url, thumbnail_url]
  ).first[0]
  
  # ステップを挿入
  if params[:steps]
    params[:steps].each_with_index do |(step_index, step_data), index|
      step_image_url = nil
      
      if step_data[:image_file] && step_data[:image_file][:tempfile]
        step_image_filename = "step_#{recipe_id}_#{index + 1}_#{step_data[:image_file][:filename]}"
        step_image_path = "public/thumbnails/#{step_image_filename}"
        File.open(step_image_path, 'wb') { |f| f.write(step_data[:image_file][:tempfile].read) }
        step_image_url = "/thumbnails/#{step_image_filename}"
      end
      
      db.execute(
        "INSERT INTO recipe_steps (recipe_id, step_number, title, description, image_url, video_timestamp) VALUES (?, ?, ?, ?, ?, ?)",
        [recipe_id, index + 1, step_data[:title], step_data[:description], step_image_url, step_data[:video_timestamp]]
      )
    end
  end
  
  db.close
  
  redirect "/recipes/#{recipe_id}"
end

# プレビュー機能
post '/recipes/preview' do
  # 一時的なレシピデータを作成
  @recipe = {
    'title' => params[:title],
    'description' => params[:description],
    'industry' => params[:industry],
    'purpose' => params[:purpose],
    'difficulty_level' => params[:difficulty_level],
    'duration_minutes' => params[:duration_minutes],
    'access_level' => params[:access_level],
    'preview_seconds' => params[:preview_seconds],
    'ingredients' => params[:ingredients],
    'instructions' => params[:instructions],
    'tips' => params[:tips],
    'video_url' => '/videos/sample.mp4', # プレビュー用のサンプル
    'thumbnail_url' => '/thumbnails/sample.jpg'
  }
  
  @steps = []
  if params[:steps]
    params[:steps].each_with_index do |(step_index, step_data), index|
      @steps << {
        'title' => step_data[:title],
        'description' => step_data[:description],
        'image_url' => '/thumbnails/sample_step.jpg', # プレビュー用のサンプル
        'video_timestamp' => step_data[:video_timestamp]
      }
    end
  end
  
  erb :recipe_detail, layout: false
end

# ホーム画面プレビュー
get '/preview/home' do
  # サンプルレシピデータを作成
  sample_recipes = [
    {
      'id' => 1,
      'title' => 'ChatGPTで効率的な議事録作成',
      'description' => '会議の音声をテキスト化し、ChatGPTで見やすい議事録に整形する方法',
      'industry' => 'IT・システム',
      'purpose' => 'AI活用',
      'difficulty_level' => '初級',
      'duration_minutes' => 15,
      'access_level' => 'free',
      'thumbnail_url' => '/thumbnails/sample.jpg'
    },
    {
      'id' => 2,
      'title' => 'プレゼン資料を10分で作成',
      'description' => 'ChatGPTを使って企画書やプレゼン資料のアウトラインを素早く作成',
      'industry' => '企画・マーケティング',
      'purpose' => '文書作成',
      'difficulty_level' => '中級',
      'duration_minutes' => 10,
      'access_level' => 'free',
      'thumbnail_url' => '/thumbnails/sample.jpg'
    },
    {
      'id' => 3,
      'title' => 'メール返信の自動化テクニック',
      'description' => '定型的なメール返信をChatGPTで効率化する実践的な方法',
      'industry' => '総務・人事',
      'purpose' => 'AI活用',
      'difficulty_level' => '中級',
      'duration_minutes' => 20,
      'access_level' => 'premium',
      'thumbnail_url' => '/thumbnails/sample.jpg'
    },
    {
      'id' => 4,
      'title' => 'SNS投稿コンテンツ生成術',
      'description' => 'ブランドに合ったSNS投稿をChatGPTで継続的に作成する方法',
      'industry' => 'デザイン・クリエイティブ',
      'purpose' => 'アイデア発想',
      'difficulty_level' => '初級',
      'duration_minutes' => 12,
      'access_level' => 'free',
      'thumbnail_url' => '/thumbnails/sample.jpg'
    },
    {
      'id' => 5,
      'title' => '顧客対応チャットボット設計',
      'description' => 'よくある質問への自動回答システムをChatGPTで構築',
      'industry' => 'IT・システム',
      'purpose' => 'AI活用',
      'difficulty_level' => '上級',
      'duration_minutes' => 35,
      'access_level' => 'premium',
      'thumbnail_url' => '/thumbnails/sample.jpg'
    },
    {
      'id' => 6,
      'title' => 'データ分析レポート自動生成',
      'description' => 'Excelデータを読み込んでChatGPTで分析レポートを作成',
      'industry' => '企画・マーケティング',
      'purpose' => 'データ分析',
      'difficulty_level' => '中級',
      'duration_minutes' => 25,
      'access_level' => 'free',
      'thumbnail_url' => '/thumbnails/sample.jpg'
    }
  ]
  
  erb :index, locals: { recipes: sample_recipes }
end

# プレビュー用のサンプルページ
get '/preview' do
  @recipe = {
    'title' => 'サンプルレシピ：ChatGPTで効率的な文書作成',
    'description' => 'ChatGPTを活用して、業務文書を効率的に作成する方法を学びます。',
    'industry' => 'IT・システム',
    'purpose' => 'AI活用',
    'difficulty_level' => '中級',
    'duration_minutes' => 20,
    'access_level' => 'free',
    'preview_seconds' => 60,
    'ingredients' => '<ul><li>ChatGPT アカウント</li><li>パソコンまたはスマートフォン</li><li>作成したい文書の概要</li></ul>',
    'instructions' => '<ol><li>ChatGPTにアクセス</li><li>文書の目的と形式を指定</li><li>必要な情報を入力</li><li>生成された文書を確認・修正</li></ol>',
    'tips' => '<p>具体的な指示を出すことで、より精度の高い文書が生成されます。複数回のやり取りで内容を改善していきましょう。</p>',
    'video_url' => '/videos/sample.mp4',
    'thumbnail_url' => '/thumbnails/sample.jpg'
  }
  
  @steps = [
    {
      'title' => 'ChatGPTにアクセスして目的を伝える',
      'description' => 'ChatGPTを開き、作成したい文書の種類と目的を明確に伝えます。例：「会議の議事録を作成したい」「提案書のアウトラインが欲しい」など。',
      'image_url' => '/thumbnails/sample_step.jpg',
      'video_timestamp' => 30
    },
    {
      'title' => '必要な情報と条件を入力する',
      'description' => '文書に含めたい内容、文字数、対象読者などの条件を具体的に指定します。詳細な情報を提供するほど、適切な文書が生成されます。',
      'image_url' => '/thumbnails/sample_step.jpg',
      'video_timestamp' => 120
    },
    {
      'title' => '生成された文書を確認・調整する',
      'description' => 'ChatGPTが生成した文書を確認し、必要に応じて修正や追加の指示を出します。「もう少し詳しく」「簡潔にして」などの調整が可能です。',
      'image_url' => '/thumbnails/sample_step.jpg',
      'video_timestamp' => 240
    }
  ]
  
  erb :recipe_detail
end

# プレビューナビゲーションページ
get '/preview/nav' do
  erb :preview_nav
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