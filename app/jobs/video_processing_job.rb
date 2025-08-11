class VideoProcessingJob < ApplicationJob
  queue_as :video_processing
  
  def perform(recipe_id, source_video_path)
    recipe = Recipe.find(recipe_id)
    
    Rails.logger.info "動画処理ジョブ開始: Recipe ID #{recipe_id}"
    
    begin
      # 動画処理サービスを実行
      service = VideoProcessingService.new(recipe_id, source_video_path)
      result = service.process_and_upload
      
      if result[:success]
        # 処理成功時の更新
        recipe.update!(
          hls_master_url: extract_s3_key(result[:master_playlist_url]),
          thumbnail_s3_key: extract_s3_key(result[:thumbnail_url]),
          video_qualities: result[:quality_variants].to_json,
          processing_status: 'completed',
          processed_at: Time.current
        )
        
        Rails.logger.info "動画処理ジョブ完了: Recipe ID #{recipe_id}"
        
        # 処理完了通知（必要に応じて）
        # NotificationService.notify_video_processing_completed(recipe)
        
      else
        # 処理失敗時
        recipe.update!(
          processing_status: 'failed',
          processing_error: result[:error]
        )
        
        Rails.logger.error "動画処理ジョブ失敗: Recipe ID #{recipe_id}, Error: #{result[:error]}"
      end
      
    rescue => e
      # 予期しないエラー
      recipe.update!(
        processing_status: 'failed',
        processing_error: e.message
      )
      
      Rails.logger.error "動画処理ジョブエラー: Recipe ID #{recipe_id}, Error: #{e.message}"
      raise e
    ensure
      # 元動画ファイルを削除（必要に応じて）
      File.delete(source_video_path) if File.exist?(source_video_path)
    end
  end
  
  private
  
  def extract_s3_key(signed_url)
    # 署名付きURLからS3キーを抽出
    return nil unless signed_url
    
    uri = URI.parse(signed_url)
    uri.path[1..-1] # 先頭の "/" を除去
  end
end