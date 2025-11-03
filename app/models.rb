require 'bcrypt'
require_relative '../db/database'

module Models
  class Base
    def self.db
      Database.connection
    end

    def self.find(id)
      result = db.execute("SELECT * FROM #{table_name} WHERE id = ? LIMIT 1", [id]).first
      result ? new(result) : nil
    end

    def self.all
      db.execute("SELECT * FROM #{table_name} ORDER BY created_at DESC").map { |row| new(row) }
    end

    def self.where(conditions)
      where_clause = conditions.keys.map { |k| "#{k} = ?" }.join(" AND ")
      values = conditions.values
      db.execute("SELECT * FROM #{table_name} WHERE #{where_clause}", values).map { |row| new(row) }
    end

    def self.table_name
      # ModelsプレフィックスとBase classを削除して複数形に
      name.split('::').last.gsub(/([A-Z])/, '_\1').downcase[1..-1] + 's'
    end

    def initialize(attributes = {})
      attributes.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end

    def [](key)
      instance_variable_get("@#{key}")
    end

    def []=(key, value)
      instance_variable_set("@#{key}", value)
    end
  end

  class Recipe < Base
    attr_accessor :id, :title, :description, :video_url, :thumbnail_url,
                  :industry, :purpose, :difficulty_level, :duration_minutes,
                  :access_level, :preview_seconds, :hls_master_url,
                  :thumbnail_s3_key, :video_qualities, :processing_status,
                  :view_count, :save_count, :rating_average, :rating_count,
                  :created_at, :updated_at

    def self.table_name
      'recipes'
    end

    def self.search(query:, industry: nil, difficulty: nil, access_level: nil, limit: 20, offset: 0)
      conditions = []
      values = []

      if query && !query.empty?
        conditions << "(title LIKE ? OR description LIKE ?)"
        values << "%#{query}%"
        values << "%#{query}%"
      end

      if industry && !industry.empty?
        conditions << "industry = ?"
        values << industry
      end

      if difficulty && !difficulty.empty?
        conditions << "difficulty_level = ?"
        values << difficulty
      end

      if access_level && !access_level.empty?
        conditions << "access_level = ?"
        values << access_level
      end

      where_clause = conditions.any? ? "WHERE #{conditions.join(' AND ')}" : ""
      sql = "SELECT * FROM recipes #{where_clause} ORDER BY created_at DESC LIMIT ? OFFSET ?"
      values << limit << offset

      db.execute(sql, values).map { |row| new(row) }
    end

    def self.popular(limit = 10)
      db.execute(
        "SELECT * FROM recipes ORDER BY view_count DESC, rating_average DESC LIMIT ?",
        [limit]
      ).map { |row| new(row) }
    end

    def steps
      RecipeStep.where(recipe_id: @id)
    end

    def tags
      sql = <<-SQL
        SELECT tags.* FROM tags
        INNER JOIN recipe_tags ON tags.id = recipe_tags.tag_id
        WHERE recipe_tags.recipe_id = ?
      SQL
      self.class.db.execute(sql, [@id]).map { |row| Tag.new(row) }
    end

    def increment_view_count!
      self.class.db.execute(
        "UPDATE recipes SET view_count = view_count + 1, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
        [@id]
      )
    end

    def update_rating!(new_rating)
      current_total = (@rating_average || 0) * (@rating_count || 0)
      new_count = (@rating_count || 0) + 1
      new_average = (current_total + new_rating) / new_count.to_f

      self.class.db.execute(
        "UPDATE recipes SET rating_average = ?, rating_count = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
        [new_average, new_count, @id]
      )

      @rating_average = new_average
      @rating_count = new_count
    end

    def to_h
      {
        id: @id,
        title: @title,
        description: @description,
        video_url: @video_url,
        thumbnail_url: @thumbnail_url,
        industry: @industry,
        purpose: @purpose,
        difficulty_level: @difficulty_level,
        duration_minutes: @duration_minutes,
        access_level: @access_level,
        view_count: @view_count || 0,
        save_count: @save_count || 0,
        rating_average: @rating_average || 0.0,
        rating_count: @rating_count || 0,
        created_at: @created_at
      }
    end
  end

  class RecipeStep < Base
    attr_accessor :id, :recipe_id, :step_number, :title, :description,
                  :image_url, :prompt_example, :technique_note,
                  :created_at, :updated_at

    def self.table_name
      'recipe_steps'
    end

    def to_h
      {
        id: @id,
        recipe_id: @recipe_id,
        step_number: @step_number,
        title: @title,
        description: @description,
        image_url: @image_url,
        prompt_example: @prompt_example,
        technique_note: @technique_note
      }
    end
  end

  class Tag < Base
    attr_accessor :id, :name, :category, :created_at, :updated_at

    def self.table_name
      'tags'
    end

    def self.find_or_create(name, category = 'general')
      existing = db.execute("SELECT * FROM tags WHERE name = ? LIMIT 1", [name]).first
      return new(existing) if existing

      db.execute("INSERT INTO tags (name, category) VALUES (?, ?)", [name, category])
      find(db.last_insert_row_id)
    end

    def recipes
      sql = <<-SQL
        SELECT recipes.* FROM recipes
        INNER JOIN recipe_tags ON recipes.id = recipe_tags.recipe_id
        WHERE recipe_tags.tag_id = ?
      SQL
      self.class.db.execute(sql, [@id]).map { |row| Recipe.new(row) }
    end

    def to_h
      {
        id: @id,
        name: @name,
        category: @category
      }
    end
  end

  class User < Base
    attr_accessor :id, :email, :password_digest, :name, :subscription_level,
                  :subscription_expires_at, :reset_password_token,
                  :reset_password_sent_at, :last_sign_in_at,
                  :created_at, :updated_at

    def self.table_name
      'users'
    end

    def self.find_by_email(email)
      result = db.execute("SELECT * FROM users WHERE email = ? LIMIT 1", [email]).first
      result ? new(result) : nil
    end

    def self.authenticate(email, password)
      user = find_by_email(email)
      return nil unless user

      if BCrypt::Password.new(user.password_digest) == password
        user.update_last_sign_in!
        user
      else
        nil
      end
    end

    def self.create(email:, password:, name: nil, subscription_level: 'free')
      password_digest = BCrypt::Password.create(password)
      db.execute(
        "INSERT INTO users (email, password_digest, name, subscription_level) VALUES (?, ?, ?, ?)",
        [email, password_digest, name, subscription_level]
      )
      find(db.last_insert_row_id)
    end

    def update_last_sign_in!
      self.class.db.execute(
        "UPDATE users SET last_sign_in_at = CURRENT_TIMESTAMP WHERE id = ?",
        [@id]
      )
    end

    def premium?
      @subscription_level == 'premium' &&
        (@subscription_expires_at.nil? || Time.parse(@subscription_expires_at) > Time.now)
    end

    def saved_recipes
      sql = <<-SQL
        SELECT recipes.* FROM recipes
        INNER JOIN user_actions ON recipes.id = user_actions.recipe_id
        WHERE user_actions.user_id = ? AND user_actions.action_type = 'save'
        ORDER BY user_actions.created_at DESC
      SQL
      self.class.db.execute(sql, [@id]).map { |row| Recipe.new(row) }
    end

    def viewed_recipes
      sql = <<-SQL
        SELECT recipes.*, MAX(user_actions.created_at) as last_viewed
        FROM recipes
        INNER JOIN user_actions ON recipes.id = user_actions.recipe_id
        WHERE user_actions.user_id = ? AND user_actions.action_type = 'view'
        GROUP BY recipes.id
        ORDER BY last_viewed DESC
      SQL
      self.class.db.execute(sql, [@id]).map { |row| Recipe.new(row) }
    end

    def to_h
      {
        id: @id,
        email: @email,
        name: @name,
        subscription_level: @subscription_level,
        subscription_expires_at: @subscription_expires_at,
        created_at: @created_at
      }
    end
  end

  class UserAction < Base
    attr_accessor :id, :user_id, :recipe_id, :action_type, :rating,
                  :comment, :progress_seconds, :created_at, :updated_at

    def self.table_name
      'user_actions'
    end

    def self.record(user_id:, recipe_id:, action_type:, rating: nil, comment: nil, progress_seconds: nil)
      # 既存のアクションがあるかチェック（view以外）
      if action_type != 'view'
        existing = db.execute(
          "SELECT * FROM user_actions WHERE user_id = ? AND recipe_id = ? AND action_type = ? LIMIT 1",
          [user_id, recipe_id, action_type]
        ).first

        if existing
          # 更新
          db.execute(
            "UPDATE user_actions SET rating = ?, comment = ?, progress_seconds = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            [rating, comment, progress_seconds, existing['id']]
          )
          return find(existing['id'])
        end
      end

      # 新規作成
      db.execute(
        "INSERT INTO user_actions (user_id, recipe_id, action_type, rating, comment, progress_seconds) VALUES (?, ?, ?, ?, ?, ?)",
        [user_id, recipe_id, action_type, rating, comment, progress_seconds]
      )

      # レシピの統計を更新
      case action_type
      when 'save'
        db.execute("UPDATE recipes SET save_count = save_count + 1 WHERE id = ?", [recipe_id])
      when 'rate'
        recipe = Recipe.find(recipe_id)
        recipe.update_rating!(rating) if recipe && rating
      end

      find(db.last_insert_row_id)
    end

    def user
      User.find(@user_id)
    end

    def recipe
      Recipe.find(@recipe_id)
    end

    def to_h
      {
        id: @id,
        user_id: @user_id,
        recipe_id: @recipe_id,
        action_type: @action_type,
        rating: @rating,
        comment: @comment,
        progress_seconds: @progress_seconds,
        created_at: @created_at
      }
    end
  end
end
