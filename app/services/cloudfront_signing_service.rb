class CloudfrontSigningService
  def initialize
    @cloudfront_client = Aws::CloudFront::Client.new
    @distribution_domain = Rails.application.credentials.aws[:cloudfront_domain]
    @key_pair_id = Rails.application.credentials.aws[:cloudfront_key_pair_id]
    @private_key = Rails.application.credentials.aws[:cloudfront_private_key]
  end
  
  def signed_url(s3_key, expires_in: 1.hour)
    # CloudFrontの署名付きURL生成
    url = "https://#{@distribution_domain}/#{s3_key}"
    expires_at = Time.current + expires_in
    
    # カスタムポリシーを使用した署名付きURL
    policy = generate_policy(url, expires_at)
    signature = sign_policy(policy)
    
    "#{url}?Expires=#{expires_at.to_i}&Signature=#{signature}&Key-Pair-Id=#{@key_pair_id}"
  end
  
  def signed_url_with_user_access(s3_key, user, expires_in: 1.hour)
    # ユーザーのアクセス権限をチェック
    return nil unless user_can_access?(user, s3_key)
    
    signed_url(s3_key, expires_in: expires_in)
  end
  
  private
  
  def generate_policy(url, expires_at)
    policy = {
      "Statement" => [
        {
          "Resource" => url,
          "Condition" => {
            "DateLessThan" => {
              "AWS:EpochTime" => expires_at.to_i
            }
          }
        }
      ]
    }
    
    Base64.strict_encode64(policy.to_json).tr('+/=', '-_~')
  end
  
  def sign_policy(policy)
    private_key = OpenSSL::PKey::RSA.new(@private_key)
    signature = private_key.sign(OpenSSL::Digest::SHA1.new, policy)
    Base64.strict_encode64(signature).tr('+/=', '-_~')
  end
  
  def user_can_access?(user, s3_key)
    # レシピIDを抽出
    recipe_id = extract_recipe_id_from_key(s3_key)
    return false unless recipe_id
    
    recipe = Recipe.find_by(id: recipe_id)
    return false unless recipe
    
    # 無料コンテンツは誰でもアクセス可能
    return true if recipe.access_level == 'free'
    
    # プレミアムコンテンツはログインユーザーのみ
    return false unless user
    
    # ユーザーのサブスクリプション状態をチェック
    user.has_premium_access?
  end
  
  def extract_recipe_id_from_key(s3_key)
    # "videos/123/master.m3u8" から "123" を抽出
    match = s3_key.match(/videos\/(\d+)\//)
    match ? match[1].to_i : nil
  end
end