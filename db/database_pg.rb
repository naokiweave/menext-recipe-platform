require 'pg'
require 'bcrypt'

class Database
  def self.connection
    # 環境変数またはデフォルト設定でPostgreSQLに接続
    @connection ||= PG.connect(
      host: ENV['DATABASE_HOST'] || 'localhost',
      port: ENV['DATABASE_PORT'] || 5432,
      dbname: ENV['DATABASE_NAME'] || 'minext_development',
      user: ENV['DATABASE_USER'] || ENV['USER'],
      password: ENV['DATABASE_PASSWORD']
    )
  end

  def self.exec(sql, params = [])
    connection.exec_params(sql, params)
  end

  def self.init!
    db = connection

    # Recipesテーブル
    db.exec <<-SQL
      CREATE TABLE IF NOT EXISTS recipes (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        video_url VARCHAR(500),
        thumbnail_url VARCHAR(500),
        industry VARCHAR(100) NOT NULL,
        purpose VARCHAR(100) NOT NULL,
        difficulty_level VARCHAR(50) NOT NULL,
        duration_minutes INTEGER NOT NULL,
        access_level VARCHAR(50) DEFAULT 'free',
        preview_seconds INTEGER,
        hls_master_url VARCHAR(500),
        thumbnail_s3_key VARCHAR(500),
        video_qualities TEXT,
        processing_status VARCHAR(50) DEFAULT 'pending',
        view_count INTEGER DEFAULT 0,
        save_count INTEGER DEFAULT 0,
        rating_average DECIMAL(3,2) DEFAULT 0.0,
        rating_count INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    SQL

    # Recipe Stepsテーブル
    db.exec <<-SQL
      CREATE TABLE IF NOT EXISTS recipe_steps (
        id SERIAL PRIMARY KEY,
        recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
        step_number INTEGER NOT NULL,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        image_url VARCHAR(500),
        prompt_example TEXT,
        technique_note TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(recipe_id, step_number)
      )
    SQL

    # Tagsテーブル
    db.exec <<-SQL
      CREATE TABLE IF NOT EXISTS tags (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL UNIQUE,
        category VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    SQL

    # Recipe Tagsテーブル
    db.exec <<-SQL
      CREATE TABLE IF NOT EXISTS recipe_tags (
        id SERIAL PRIMARY KEY,
        recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
        tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(recipe_id, tag_id)
      )
    SQL

    # Usersテーブル
    db.exec <<-SQL
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) NOT NULL UNIQUE,
        password_digest VARCHAR(255) NOT NULL,
        name VARCHAR(100),
        subscription_level VARCHAR(50) DEFAULT 'free',
        subscription_expires_at TIMESTAMP,
        reset_password_token VARCHAR(255),
        reset_password_sent_at TIMESTAMP,
        last_sign_in_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    SQL

    # User Actionsテーブル
    db.exec <<-SQL
      CREATE TABLE IF NOT EXISTS user_actions (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        recipe_id INTEGER NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
        action_type VARCHAR(50) NOT NULL,
        rating INTEGER,
        comment TEXT,
        progress_seconds INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    SQL

    # インデックス作成
    begin
      db.exec "CREATE INDEX IF NOT EXISTS idx_recipes_industry ON recipes(industry)"
      db.exec "CREATE INDEX IF NOT EXISTS idx_recipes_difficulty ON recipes(difficulty_level)"
      db.exec "CREATE INDEX IF NOT EXISTS idx_recipes_access_level ON recipes(access_level)"
      db.exec "CREATE INDEX IF NOT EXISTS idx_user_actions_user_recipe ON user_actions(user_id, recipe_id, action_type)"
      db.exec "CREATE INDEX IF NOT EXISTS idx_user_actions_created_at ON user_actions(created_at)"
    rescue PG::DuplicateTable, PG::DuplicateObject
      # インデックスが既に存在する場合は無視
    end

    puts "✅ PostgreSQLデータベース初期化完了"
  end

  def self.seed!
    db = connection

    # サンプルレシピデータ
    sample_recipes = [
      {
        title: '新人も理解が深まる！作業手順書のマンガ化',
        description: '複雑な作業手順を、誰でも直感的に理解できるマンガ形式に変換します。新人教育や技術継承に最適です。',
        industry: '製造・現場',
        purpose: '教育・トレーニング',
        difficulty_level: '初級',
        duration_minutes: 1,
        access_level: 'free',
        video_url: '/videos/225..mp4',
        thumbnail_url: '/thumbnails/225.jpg',
        steps: [
          {
            title: 'ChatGPTに画像をアップロードする',
            description: '用意した手順書の画像をChatGPTにアップロードします。これで画像内の文字情報も含めて自然に理解されるようになります。',
            prompt_example: 'この作業手順書をマンガ形式に変換してください。4コマ漫画で、各ステップを視覚的に分かりやすく表現してください。'
          },
          {
            title: 'マンガ化の指示を出す',
            description: '手順書をマンガ形式に変換するよう指示します。キャラクターや吹き出しを使って、より親しみやすい表現にします。'
          },
          {
            title: '内容を確認して調整する',
            description: '生成されたマンガを確認し、必要に応じて修正指示を出します。現場で実際に使えるクオリティになるまで調整しましょう。',
            technique_note: '専門用語は残しつつ、視覚的な説明を加えることで、新人でも理解しやすくなります。'
          }
        ],
        tags: ['製造・現場職場', 'ChatGPT', '初心者', '教育']
      },
      {
        title: 'ゲーム感覚で学べる！日本クイズGPT',
        description: '日本の文化や歴史をクイズ形式で学べるGPTを作成します。楽しみながら知識を深められます。',
        industry: '教育',
        purpose: '学習コンテンツ',
        difficulty_level: '初級',
        duration_minutes: 1,
        access_level: 'free',
        video_url: '/videos/recipe_2.mp4',
        thumbnail_url: '/thumbnails/recipe_2.svg',
        tags: ['教育', 'ChatGPT', '初心者']
      },
      {
        title: '店長後の10分で整う！文字起こしの清書',
        description: '会議や打ち合わせの文字起こしを、読みやすい議事録形式に整形します。',
        industry: 'オフィスワーク',
        purpose: '文書作成',
        difficulty_level: '初級',
        duration_minutes: 1,
        access_level: 'free',
        video_url: '/videos/recipe_3.mp4',
        thumbnail_url: '/thumbnails/recipe_3.svg',
        tags: ['文字起こし', 'ChatGPT', '初心者']
      }
    ]

    sample_recipes.each do |recipe|
      # レシピを挿入（既存チェック）
      existing = db.exec_params("SELECT id FROM recipes WHERE title = $1", [recipe[:title]])

      if existing.ntuples == 0
        result = db.exec_params(
          "INSERT INTO recipes (title, description, industry, purpose, difficulty_level, duration_minutes, access_level, video_url, thumbnail_url) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id",
          [recipe[:title], recipe[:description], recipe[:industry], recipe[:purpose], recipe[:difficulty_level], recipe[:duration_minutes], recipe[:access_level], recipe[:video_url], recipe[:thumbnail_url]]
        )
        recipe_id = result[0]['id'].to_i

        # 手順を挿入
        recipe[:steps]&.each_with_index do |step, index|
          db.exec_params(
            "INSERT INTO recipe_steps (recipe_id, step_number, title, description, prompt_example, technique_note) VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT (recipe_id, step_number) DO NOTHING",
            [recipe_id, index + 1, step[:title], step[:description], step[:prompt_example], step[:technique_note]]
          )
        end

        # タグを挿入
        recipe[:tags]&.each do |tag_name|
          # タグが存在しなければ作成
          db.exec_params("INSERT INTO tags (name, category) VALUES ($1, $2) ON CONFLICT (name) DO NOTHING", [tag_name, 'general'])
          tag_result = db.exec_params("SELECT id FROM tags WHERE name = $1", [tag_name])
          tag_id = tag_result[0]['id'].to_i

          # レシピとタグを関連付け
          db.exec_params("INSERT INTO recipe_tags (recipe_id, tag_id) VALUES ($1, $2) ON CONFLICT (recipe_id, tag_id) DO NOTHING", [recipe_id, tag_id])
        end
      end
    end

    # サンプルユーザーを作成
    existing_user = db.exec_params("SELECT id FROM users WHERE email = $1", ['test@example.com'])
    if existing_user.ntuples == 0
      password_digest = BCrypt::Password.create('password123')
      db.exec_params(
        "INSERT INTO users (email, password_digest, name, subscription_level) VALUES ($1, $2, $3, $4)",
        ['test@example.com', password_digest, 'テストユーザー', 'free']
      )
    end

    puts "✅ PostgreSQLシードデータ投入完了"
  end

  def self.close
    @connection&.close
    @connection = nil
  end
end
