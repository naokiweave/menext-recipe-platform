Rails.application.routes.draw do
  # API routes
  namespace :api do
    resources :recipes, only: [:index, :show]
  end
  
  # Admin routes
  namespace :admin do
    resources :recipes do
      member do
        post :upload_video
      end
    end
    
    # 簡易ログイン（本番では適切な認証を実装）
    get 'login', to: 'sessions#new'
    post 'login', to: 'sessions#create'
    delete 'logout', to: 'sessions#destroy'
  end
  
  # Public routes
  resources :recipes, only: [:show]
  root 'recipes#index'
end