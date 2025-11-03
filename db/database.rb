require 'sqlite3'
require 'bcrypt'

class Database
  def self.connection
    # スレッドごとに新しい接続を作成（マルチプロセス対応）
    Thread.current[:db_connection] ||= SQLite3::Database.new('db/minext.sqlite3').tap do |db|
      db.results_as_hash = true
      db.execute('PRAGMA foreign_keys = ON')
    end
  end

  def self.init!
    db = connection

    # Recipesテーブル
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
        hls_master_url TEXT,
        thumbnail_s3_key TEXT,
        video_qualities TEXT,
        processing_status TEXT DEFAULT 'pending',
        view_count INTEGER DEFAULT 0,
        save_count INTEGER DEFAULT 0,
        rating_average REAL DEFAULT 0.0,
        rating_count INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    SQL

    # Recipe Stepsテーブル
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS recipe_steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL,
        step_number INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        prompt_example TEXT,
        technique_note TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE,
        UNIQUE(recipe_id, step_number)
      )
    SQL

    # Tagsテーブル
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        category TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    SQL

    # Recipe Tagsテーブル
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS recipe_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE,
        UNIQUE(recipe_id, tag_id)
      )
    SQL

    # Usersテーブル
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password_digest TEXT NOT NULL,
        name TEXT,
        subscription_level TEXT DEFAULT 'free',
        subscription_expires_at DATETIME,
        reset_password_token TEXT,
        reset_password_sent_at DATETIME,
        last_sign_in_at DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    SQL

    # User Actionsテーブル
    db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS user_actions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        recipe_id INTEGER NOT NULL,
        action_type TEXT NOT NULL,
        rating INTEGER,
        comment TEXT,
        progress_seconds INTEGER,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE
      )
    SQL

    # インデックス作成
    db.execute "CREATE INDEX IF NOT EXISTS idx_recipes_industry ON recipes(industry)"
    db.execute "CREATE INDEX IF NOT EXISTS idx_recipes_difficulty ON recipes(difficulty_level)"
    db.execute "CREATE INDEX IF NOT EXISTS idx_recipes_access_level ON recipes(access_level)"
    db.execute "CREATE INDEX IF NOT EXISTS idx_user_actions_user_recipe ON user_actions(user_id, recipe_id, action_type)"
    db.execute "CREATE INDEX IF NOT EXISTS idx_user_actions_created_at ON user_actions(created_at)"

    puts "✅ データベース初期化完了"
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
      # レシピを挿入
      db.execute(
        "INSERT OR IGNORE INTO recipes (title, description, industry, purpose, difficulty_level, duration_minutes, access_level, video_url, thumbnail_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [recipe[:title], recipe[:description], recipe[:industry], recipe[:purpose], recipe[:difficulty_level], recipe[:duration_minutes], recipe[:access_level], recipe[:video_url], recipe[:thumbnail_url]]
      )

      recipe_id = db.last_insert_row_id

      # 手順を挿入
      recipe[:steps]&.each_with_index do |step, index|
        db.execute(
          "INSERT OR IGNORE INTO recipe_steps (recipe_id, step_number, title, description, prompt_example, technique_note) VALUES (?, ?, ?, ?, ?, ?)",
          [recipe_id, index + 1, step[:title], step[:description], step[:prompt_example], step[:technique_note]]
        )
      end

      # タグを挿入
      recipe[:tags]&.each do |tag_name|
        # タグが存在しなければ作成
        db.execute("INSERT OR IGNORE INTO tags (name, category) VALUES (?, ?)", [tag_name, 'general'])
        tag = db.execute("SELECT id FROM tags WHERE name = ?", [tag_name]).first
        tag_id = tag['id']

        # レシピとタグを関連付け
        db.execute("INSERT OR IGNORE INTO recipe_tags (recipe_id, tag_id) VALUES (?, ?)", [recipe_id, tag_id])
      end
    end

    # サンプルユーザーを作成
    password_digest = BCrypt::Password.create('password123')
    db.execute(
      "INSERT OR IGNORE INTO users (email, password_digest, name, subscription_level) VALUES (?, ?, ?, ?)",
      ['test@example.com', password_digest, 'テストユーザー', 'free']
    )

    puts "✅ シードデータ投入完了"
  end

  def self.close
    @connection&.close
    @connection = nil
  end
end
