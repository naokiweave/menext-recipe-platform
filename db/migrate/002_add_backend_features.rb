class AddBackendFeatures < ActiveRecord::Migration[8.0]
  def change
    # Recipe Stepsテーブル - レシピの手順を管理
    create_table :recipe_steps do |t|
      t.references :recipe, null: false, foreign_key: true
      t.integer :step_number, null: false
      t.string :title, null: false
      t.text :description
      t.string :image_url
      t.text :prompt_example
      t.text :technique_note
      t.timestamps
    end
    add_index :recipe_steps, [:recipe_id, :step_number], unique: true

    # Usersテーブル - ユーザー管理
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name
      t.string :subscription_level, default: 'free', null: false
      t.datetime :subscription_expires_at
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :last_sign_in_at
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :subscription_level

    # User Actionsテーブル - ユーザーのアクション履歴
    create_table :user_actions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.string :action_type, null: false # view, save, rate, comment
      t.integer :rating # 1-5
      t.text :comment
      t.integer :progress_seconds # 視聴進捗
      t.timestamps
    end
    add_index :user_actions, [:user_id, :recipe_id, :action_type]
    add_index :user_actions, :action_type
    add_index :user_actions, :created_at

    # Recipesテーブルに統計カラムを追加
    add_column :recipes, :view_count, :integer, default: 0
    add_column :recipes, :save_count, :integer, default: 0
    add_column :recipes, :rating_average, :decimal, precision: 3, scale: 2, default: 0.0
    add_column :recipes, :rating_count, :integer, default: 0

    # Tagsテーブルにカテゴリーを追加
    add_column :tags, :category, :string
    add_index :tags, :category
  end
end
