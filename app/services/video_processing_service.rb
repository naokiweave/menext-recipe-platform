class VideoProcessingService
  include ActiveModel::Model
  
  QUALITY_SETTINGS = {
    '240p' => { resolution: '426x240', bitrate: '400k', audio_bitrate: '64k' },
    '360p' => { resolution: '640x360', bitrate: '800k', audio_bitrate: '96k' },
    '480p' => { resolution: '854x480', bitrate: '1200k', audio_bitrate: '128k' },
    '720p' => { resolution: '1280x720', bitrate: '2500k', audio_bitrate: '128k' },
    '1080p' => { resolution: '1920x1080', bitrate: '4500k', audio_bitrate: '192k' }
  }.freeze
  
  def initialize(recipe_id, source_video_path)
    @recipe_id = recipe_id
    @source_video_path = source_video_path
    @s3_client = Aws::S3::Client.new
    @bucket_name = Rails.application.credentials.aws[:s3_bucket]
  end
  
  def process_and_upload
    Rails.logger.info "動画処理開始: Recipe ID #{@recipe_id}"
    
    # 一時ディレクトリ作成
    temp_dir = Rails.root.join('tmp', 'video_processing', @recipe_id.to_s)
    FileUtils.mkdir_p(temp_dir)
    
    begin
      # 各画質の動画を生成
      quality_variants = generate_quality_variants(temp_dir)
      
      # HLSプレイリスト生成
      master_playlist = generate_master_playlist(quality_variants)
      
      # S3にアップロード
      s3_urls = upload_to_s3(temp_dir, quality_variants, master_playlist)
      
      # CloudFront署名付きURL生成
      signed_urls = generate_signed_urls(s3_urls)
      
      Rails.logger.info "動画処理完了: Recipe ID #{@recipe_id}"
      
      {
        success: true,
        master_playlist_url: signed_urls[:master_playlist],
        thumbnail_url: signed_urls[:thumbnail],
        quality_variants: signed_urls[:variants]
      }
      
    rescue => e
      Rails.logger.error "動画処理エラー: #{e.message}"
      { success: false, error: e.message }
    ensure
      # 一時ファイル削除
      FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
    end
  end
  
  private
  
  def generate_quality_variants(temp_dir)
    movie = FFMPEG::Movie.new(@source_video_path)
    variants = {}
    
    QUALITY_SETTINGS.each do |quality, settings|
      # 元動画の解像度より高い設定はスキップ
      target_height = settings[:resolution].split('x')[1].to_i
      next if movie.height && movie.height < target_height
      
      output_dir = temp_dir.join(quality)
      FileUtils.mkdir_p(output_dir)
      
      # HLS形式で出力
      output_path = output_dir.join('playlist.m3u8')
      
      options = {
        video_codec: 'libx264',
        audio_codec: 'aac',
        video_bitrate: settings[:bitrate],
        audio_bitrate: settings[:audio_bitrate],
        resolution: settings[:resolution],
        custom: [
          '-hls_time', '6',
          '-hls_playlist_type', 'vod',
          '-hls_segment_filename', output_dir.join('segment_%03d.ts').to_s,
          '-start_number', '0'
        ]
      }
      
      movie.transcode(output_path.to_s, options)
      
      variants[quality] = {
        playlist_path: output_path,
        segments_dir: output_dir,
        bitrate: settings[:bitrate].gsub('k', '000').to_i,
        resolution: settings[:resolution]
      }
      
      Rails.logger.info "#{quality} 変換完了"
    end
    
    # サムネイル生成
    generate_thumbnail(movie, temp_dir)
    
    variants
  end
  
  def generate_thumbnail(movie, temp_dir)
    thumbnail_path = temp_dir.join('thumbnail.jpg')
    
    # 動画の10%の位置でサムネイル生成
    seek_time = movie.duration * 0.1
    
    movie.screenshot(thumbnail_path.to_s, {
      seek_time: seek_time,
      resolution: '1280x720',
      quality: 3
    })
    
    thumbnail_path
  end
  
  def generate_master_playlist(variants)
    playlist_content = "#EXTM3U\n#EXT-X-VERSION:3\n\n"
    
    variants.each do |quality, info|
      playlist_content += "#EXT-X-STREAM-INF:BANDWIDTH=#{info[:bitrate]},RESOLUTION=#{info[:resolution]}\n"
      playlist_content += "#{quality}/playlist.m3u8\n"
    end
    
    playlist_content
  end
  
  def upload_to_s3(temp_dir, variants, master_playlist)
    s3_base_path = "videos/#{@recipe_id}"
    uploaded_urls = { variants: {} }
    
    # マスタープレイリストをアップロード
    master_key = "#{s3_base_path}/master.m3u8"
    @s3_client.put_object(
      bucket: @bucket_name,
      key: master_key,
      body: master_playlist,
      content_type: 'application/vnd.apple.mpegurl'
    )
    uploaded_urls[:master_playlist] = master_key
    
    # 各画質のファイルをアップロード
    variants.each do |quality, info|
      quality_base_path = "#{s3_base_path}/#{quality}"
      
      # プレイリストファイル
      playlist_key = "#{quality_base_path}/playlist.m3u8"
      @s3_client.put_object(
        bucket: @bucket_name,
        key: playlist_key,
        body: File.read(info[:playlist_path]),
        content_type: 'application/vnd.apple.mpegurl'
      )
      
      # セグメントファイル
      Dir.glob(info[:segments_dir].join('*.ts')).each do |segment_file|
        segment_name = File.basename(segment_file)
        segment_key = "#{quality_base_path}/#{segment_name}"
        
        @s3_client.put_object(
          bucket: @bucket_name,
          key: segment_key,
          body: File.read(segment_file),
          content_type: 'video/mp2t'
        )
      end
      
      uploaded_urls[:variants][quality] = playlist_key
    end
    
    # サムネイルアップロード
    thumbnail_path = temp_dir.join('thumbnail.jpg')
    if File.exist?(thumbnail_path)
      thumbnail_key = "#{s3_base_path}/thumbnail.jpg"
      @s3_client.put_object(
        bucket: @bucket_name,
        key: thumbnail_key,
        body: File.read(thumbnail_path),
        content_type: 'image/jpeg'
      )
      uploaded_urls[:thumbnail] = thumbnail_key
    end
    
    uploaded_urls
  end
  
  def generate_signed_urls(s3_urls)
    cloudfront_service = CloudfrontSigningService.new
    signed_urls = {}
    
    # マスタープレイリストの署名付きURL
    signed_urls[:master_playlist] = cloudfront_service.signed_url(s3_urls[:master_playlist])
    
    # サムネイルの署名付きURL
    if s3_urls[:thumbnail]
      signed_urls[:thumbnail] = cloudfront_service.signed_url(s3_urls[:thumbnail])
    end
    
    # 各画質の署名付きURL
    signed_urls[:variants] = {}
    s3_urls[:variants].each do |quality, s3_key|
      signed_urls[:variants][quality] = cloudfront_service.signed_url(s3_key)
    end
    
    signed_urls
  end
end