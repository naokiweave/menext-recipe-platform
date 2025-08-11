class Admin::RecipesController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_recipe, only: [:show, :edit, :update, :destroy, :upload_video]
  
  def index
    @recipes = Recipe.all.order(created_at: :desc)
  end
  
  def show
  end
  
  def new
    @recipe = Recipe.new
  end
  
  def create
    @recipe = Recipe.new(recipe_params)
    
    if @recipe.save
      redirect_to admin_recipe_path(@recipe), notice: 'レシピが作成されました。'
    else
      render :new
    end
  end
  
  def edit
  end
  
  def update
    if @recipe.update(recipe_params)
      redirect_to admin_recipe_path(@recipe), notice: 'レシピが更新されました。'
    else
      render :edit
    end
  end
  
  def destroy
    @recipe.destroy
    redirect_to admin_recipes_path, notice: 'レシピが削除されました。'
  end
  
  # 動画アップロード処理
  def upload_video
    uploaded_file = params[:video_file]
    
    if uploaded_file.blank?
      redirect_to admin_recipe_path(@recipe), alert: '動画ファイルを選択してください。'
      return
    end
    
    # 一時ファイルとして保存
    temp_path = save_temp_video(uploaded_file)
    
    # バックグラウンドで動画処理を開始
    @recipe.start_video_processing(temp_path)
    
    redirect_to admin_recipe_path(@recipe), notice: '動画のアップロードを開始しました。処理完了まで数分かかります。'
  end
  
  private
  
  def set_recipe
    @recipe = Recipe.find(params[:id])
  end
  
  def recipe_params
    params.require(:recipe).permit(
      :title, :description, :industry, :purpose, :difficulty_level,
      :duration_minutes, :access_level, :preview_seconds,
      :ingredients, :instructions, :tips, :video_url
    )
  end
  
  def authenticate_admin!
    # 簡易的な管理者認証（本番では適切な認証を実装）
    unless session[:admin_authenticated]
      redirect_to admin_login_path
    end
  end
  
  def save_temp_video(uploaded_file)
    # アップロードされたファイルを一時ディレクトリに保存
    temp_dir = Rails.root.join('tmp', 'uploads')
    FileUtils.mkdir_p(temp_dir)
    
    filename = "#{SecureRandom.uuid}_#{uploaded_file.original_filename}"
    temp_path = temp_dir.join(filename)
    
    File.open(temp_path, 'wb') do |file|
      file.write(uploaded_file.read)
    end
    
    temp_path.to_s
  end
end