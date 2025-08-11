class Recipe < ApplicationRecord
  validates :title, presence: true
  validates :description, presence: true
  
  # HLS配信用のフィールド
  # video_url は従来の単一動画URL（後方互換性のため残す）
  # hls_master_url は HLSマスタープレイリストのURL
  
  # 業種・用途・難易度での検索用
  validates :industry, presence: true
  validates :purpose, presence: true
  validates :difficulty_level, inclusion: { in: %w[初級 中級 上級] }
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  
  # タグ機能
  has_many :recipe_tags, dependent: :destroy
  has_many :tags, through: :recipe_tags
  
  # 視聴権限
  validates :access_level, inclusion: { in: %w[free premium] }
  validates :preview_seconds, numericality: { greater_than: 0 }, allow_nil: true
  
  scope :by_industry, ->(industry) { where(industry: industry) if industry.present? }
  scope :by_purpose, ->(purpose) { where(purpose: purpose) if purpose.present? }
  scope :by_difficulty, ->(level) { where(difficulty_level: level) if level.present? }
  scope :by_access_level, ->(level) { where(access_level: level) if level.present? }
  
  def formatted_duration
    hours = duration_minutes / 60
    minutes = duration_minutes % 60
    
    if hours > 0
      "#{hours}時間#{minutes}分"
    else
      "#{minutes}分"
    end
  end
  
  def preview_available?
    access_level == 'premium' && preview_seconds.present?
  end
  
  # HLS配信関連メソッド
  def has_hls_video?
    hls_master_url.present?
  end
  
  def video_streaming_url(user = nil)
    if has_hls_video?
      # HLS配信の署名付きURL生成
      cloudfront_service = CloudfrontSigningService.new
      cloudfront_service.signed_url_with_user_access(hls_master_url, user)
    else
      # 従来の動画URL（開発・テスト用）
      video_url
    end
  end
  
  def thumbnail_streaming_url
    return nil unless thumbnail_s3_key.present?
    
    cloudfront_service = CloudfrontSigningService.new
    cloudfront_service.signed_url(thumbnail_s3_key, expires_in: 24.hours)
  end
  
  def available_qualities
    return [] unless video_qualities.present?
    
    JSON.parse(video_qualities).keys
  end
  
  def processing_status
    # 動画処理状態: pending, processing, completed, failed
    read_attribute(:processing_status) || 'pending'
  end
  
  def processing_completed?
    processing_status == 'completed'
  end
  
  def start_video_processing(source_video_path)
    update!(processing_status: 'processing')
    
    # バックグラウンドジョブで動画処理を実行
    VideoProcessingJob.perform_later(id, source_video_path)
  end
end