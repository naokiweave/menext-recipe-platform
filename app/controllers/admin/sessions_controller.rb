class Admin::SessionsController < ApplicationController
  def new
  end
  
  def create
    # 簡易的な認証（本番では適切な認証を実装）
    if params[:password] == Rails.application.credentials.admin_password
      session[:admin_authenticated] = true
      redirect_to admin_recipes_path, notice: 'ログインしました。'
    else
      flash.now[:alert] = 'パスワードが間違っています。'
      render :new
    end
  end
  
  def destroy
    session[:admin_authenticated] = nil
    redirect_to admin_login_path, notice: 'ログアウトしました。'
  end
end