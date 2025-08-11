class CreateInitialSchema < ActiveRecord::Migration[7.0]
  def change
    # レシピテーブル
    create_table :recipes do |t|
      t.string :title, null: false
      t.text :description
      t.string :video_url
      t.string :thumbnail_url
      
      # ミーネクスト特化の検索軸
      t.string :industry, null: false
      t.string :purpose, null: false
      t.string :difficulty_level, null: false
      t.integer :duration_minutes, null: false
      
      # アクセス制御
      t.string :access_level, default: 'free', null: false
      t.integer :preview_seconds
      
      # コンテンツ
      t.text :ingredients
      t.text :instructions
      t.text :tips
      
      # HLS配信用フィールド
      t.string :hls_master_url
      t.string :thumbnail_s3_key
      t.text :video_qualities
      t.string :processing_status, default: 'pending'
      t.text :processing_error
      t.datetime :processed_at
      
      t.timestamps
    end
    
    # タグテーブル
    create_table :tags do |t|
      t.string :name, null: false
      t.timestamps
    end
    
    # レシピタグ中間テーブル
    create_table :recipe_tags do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps
    end
    
    # インデックス
    add_index :recipes, :industry
    add_index :recipes, :purpose
    add_index :recipes, :difficulty_level
    add_index :recipes, :access_level
    add_index :recipes, :processing_status
    add_index :recipes, :hls_master_url
    add_index :tags, :name, unique: true
    add_index :recipe_tags, [:recipe_id, :tag_id], unique: true
  end
end