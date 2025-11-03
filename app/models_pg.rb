require 'bcrypt'
require_relative '../db/database_pg'

module Models
  class Base
    def self.db
      Database.connection
    end

    def self.exec(sql, params = [])
      Database.exec(sql, params)
    end

    def self.find(id)
      result = exec("SELECT * FROM #{table_name} WHERE id = $1 LIMIT 1", [id])
      result.ntuples > 0 ? new(result[0]) : nil
    end

    def self.all
      result = exec("SELECT * FROM #{table_name} ORDER BY created_at DESC")
      result.map { |row| new(row) }
    end

    def self.where(conditions)
      where_clause = conditions.keys.map.with_index(1) { |k, i| "#{k} = $#{i}" }.join(" AND ")
      values = conditions.values
      result = exec("SELECT * FROM #{table_name} WHERE #{where_clause}", values)
      result.map { |row| new(row) }
    end

    def self.table_name
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
      param_index = 1

      if query && !query.empty?
        conditions << "(title ILIKE $#{param_index} OR description ILIKE $#{param_index + 1})"
        values << "%#{query}%"
        values << "%#{query}%"
        param_index += 2
      end

      if industry && !industry.empty?
        conditions << "industry = $#{param_index}"
        values << industry
        param_index += 1
      end

      if difficulty && !difficulty.empty?
        conditions << "difficulty_level = $#{param_index}"
        values << difficulty
        param_index += 1
      end

      if access_level && !access_level.empty?
        conditions << "access_level = $#{param_index}"
        values << access_level
        param_index += 1
      end

      where_clause = conditions.any? ? "WHERE #{conditions.join(' AND ')}" : ""
      sql = "SELECT * FROM recipes #{where_clause} ORDER BY created_at DESC LIMIT $#{param_index} OFFSET $#{param_index + 1}"
      values << limit << offset

      result = exec(sql, values)
      result.map { |row| new(row) }
    end

    def self.popular(limit = 10)
      result = exec(
        "SELECT * FROM recipes ORDER BY view_count DESC, rating_average DESC LIMIT $1",
        [limit]
      )
      result.map { |row| new(row) }
    end

    def steps
      RecipeStep.where(recipe_id: @id)
    end

    def tags
      sql = <<-SQL
        SELECT tags.* FROM tags
        INNER JOIN recipe_tags ON tags.id = recipe_tags.tag_id
        WHERE recipe_tags.recipe_id = $1
      SQL
      result = self.class.exec(sql, [@id])
      result.map { |row| Tag.new(row) }
    end

    def increment_view_count!
      self.class.exec(
        "UPDATE recipes SET view_count = view_count + 1, updated_at = CURRENT_TIMESTAMP WHERE id = $1",
        [@id]
      )
    end

    def update_rating!(new_rating)
      current_total = (@rating_average.to_f || 0) * (@rating_count.to_i || 0)
      new_count = (@rating_count.to_i || 0) + 1
      new_average = (current_total + new_rating) / new_count.to_f

      self.class.exec(
        "UPDATE recipes SET rating_average = $1, rating_count = $2, updated_at = CURRENT_TIMESTAMP WHERE id = $3",
        [new_average, new_count, @id]
      )

      @rating_average = new_average
      @rating_count = new_count
    end

    def to_h
      {
        id: @id.to_i,
        title: @title,
        description: @description,
        video_url: @video_url,
        thumbnail_url: @thumbnail_url,
        industry: @industry,
        purpose: @purpose,
        difficulty_level: @difficulty_level,
        duration_minutes: @duration_minutes.to_i,
        access_level: @access_level,
        view_count: (@view_count || 0).to_i,
        save_count: (@save_count || 0).to_i,
        rating_average: (@rating_average || 0.0).to_f,
        rating_count: (@rating_count || 0).to_i,
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
        id: @id.to_i,
        recipe_id: @recipe_id.to_i,
        step_number: @step_number.to_i,
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
      result = exec("SELECT * FROM tags WHERE name = $1 LIMIT 1", [name])
      return new(result[0]) if result.ntuples > 0

      exec("INSERT INTO tags (name, category) VALUES ($1, $2) RETURNING id", [name, category])
      result = exec("SELECT * FROM tags WHERE name = $1 LIMIT 1", [name])
      new(result[0])
    end

    def recipes
      sql = <<-SQL
        SELECT recipes.* FROM recipes
        INNER JOIN recipe_tags ON recipes.id = recipe_tags.recipe_id
        WHERE recipe_tags.tag_id = $1
      SQL
      result = self.class.exec(sql, [@id])
      result.map { |row| Recipe.new(row) }
    end

    def to_h
      {
        id: @id.to_i,
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
      result = exec("SELECT * FROM users WHERE email = $1 LIMIT 1", [email])
      result.ntuples > 0 ? new(result[0]) : nil
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
      result = exec(
        "INSERT INTO users (email, password_digest, name, subscription_level) VALUES ($1, $2, $3, $4) RETURNING id",
        [email, password_digest, name, subscription_level]
      )
      find(result[0]['id'].to_i)
    end

    def update_last_sign_in!
      self.class.exec(
        "UPDATE users SET last_sign_in_at = CURRENT_TIMESTAMP WHERE id = $1",
        [@id]
      )
    end

    def premium?
      @subscription_level == 'premium' &&
        (@subscription_expires_at.nil? || Time.parse(@subscription_expires_at.to_s) > Time.now)
    end

    def saved_recipes
      sql = <<-SQL
        SELECT recipes.* FROM recipes
        INNER JOIN user_actions ON recipes.id = user_actions.recipe_id
        WHERE user_actions.user_id = $1 AND user_actions.action_type = 'save'
        ORDER BY user_actions.created_at DESC
      SQL
      result = self.class.exec(sql, [@id])
      result.map { |row| Recipe.new(row) }
    end

    def viewed_recipes
      sql = <<-SQL
        SELECT recipes.*, MAX(user_actions.created_at) as last_viewed
        FROM recipes
        INNER JOIN user_actions ON recipes.id = user_actions.recipe_id
        WHERE user_actions.user_id = $1 AND user_actions.action_type = 'view'
        GROUP BY recipes.id
        ORDER BY last_viewed DESC
      SQL
      result = self.class.exec(sql, [@id])
      result.map { |row| Recipe.new(row) }
    end

    def to_h
      {
        id: @id.to_i,
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
        result = exec(
          "SELECT * FROM user_actions WHERE user_id = $1 AND recipe_id = $2 AND action_type = $3 LIMIT 1",
          [user_id, recipe_id, action_type]
        )

        if result.ntuples > 0
          # 更新
          exec(
            "UPDATE user_actions SET rating = $1, comment = $2, progress_seconds = $3, updated_at = CURRENT_TIMESTAMP WHERE id = $4",
            [rating, comment, progress_seconds, result[0]['id']]
          )
          return find(result[0]['id'].to_i)
        end
      end

      # 新規作成
      result = exec(
        "INSERT INTO user_actions (user_id, recipe_id, action_type, rating, comment, progress_seconds) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id",
        [user_id, recipe_id, action_type, rating, comment, progress_seconds]
      )

      # レシピの統計を更新
      case action_type
      when 'save'
        exec("UPDATE recipes SET save_count = save_count + 1 WHERE id = $1", [recipe_id])
      when 'rate'
        recipe = Recipe.find(recipe_id)
        recipe.update_rating!(rating) if recipe && rating
      end

      find(result[0]['id'].to_i)
    end

    def user
      User.find(@user_id.to_i)
    end

    def recipe
      Recipe.find(@recipe_id.to_i)
    end

    def to_h
      {
        id: @id.to_i,
        user_id: @user_id.to_i,
        recipe_id: @recipe_id.to_i,
        action_type: @action_type,
        rating: @rating&.to_i,
        comment: @comment,
        progress_seconds: @progress_seconds&.to_i,
        created_at: @created_at
      }
    end
  end
end
