#!/usr/bin/env ruby

require 'bundler/setup'
require 'sinatra'
require 'sinatra/cookies'
require 'json'
require_relative 'db/database'
require_relative 'app/models'

# データベース初期化
Database.init!

# セッション設定
enable :sessions
set :session_secret, ENV.fetch('SESSION_SECRET') { 'minext_secret_key_change_in_production_must_be_32_bytes_long_at_least' }

# サーバー設定
set :port, ENV['PORT'] || 4567
set :bind, '0.0.0.0'
set :public_folder, 'public'
set :static, true
set :server, :puma
set :server_settings, {
  Workers: 0  # シングルモード
}

# MIME type設定
mime_type :mp4, 'video/mp4'
mime_type :webm, 'video/webm'
mime_type :m3u8, 'application/vnd.apple.mpegurl'
mime_type :ts, 'video/mp2t'

# ヘルパーメソッド
helpers do
  def current_user
    @current_user ||= Models::User.find(session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def require_login!
    unless logged_in?
      halt 401, { error: 'ログインが必要です' }.to_json
    end
  end

  def json_response(data, status = 200)
    content_type :json
    status status
    data.to_json
  end
end

# ========== フロントエンド ルート ==========

get '/' do
  recipes = Models::Recipe.all.take(12)
  erb :index, locals: { recipes: recipes.map(&:to_h) }
end

get '/recipes/:id' do
  recipe = Models::Recipe.find(params[:id])
  halt 404, "Recipe not found" unless recipe

  # 視聴カウント増加
  recipe.increment_view_count!

  steps = recipe.steps.map(&:to_h)
  tags = recipe.tags.map(&:to_h)

  erb :recipe_detail, locals: {
    recipe: recipe.to_h,
    steps: steps,
    tags: tags
  }
end

# 検索ページ
get '/search' do
  query = params[:q]
  industry = params[:industry]
  difficulty = params[:difficulty]

  recipes = Models::Recipe.search(
    query: query,
    industry: industry,
    difficulty: difficulty,
    limit: params[:limit] || 20,
    offset: params[:offset] || 0
  )

  erb :search_results, locals: { recipes: recipes.map(&:to_h), query: query }
end

# ========== 認証 ルート ==========

get '/login' do
  erb :login
end

post '/login' do
  user = Models::User.authenticate(params[:email], params[:password])

  if user
    session[:user_id] = user.id
    redirect params[:redirect] || '/'
  else
    @error = 'メールアドレスまたはパスワードが正しくありません'
    erb :login
  end
end

get '/signup' do
  erb :signup
end

post '/signup' do
  begin
    user = Models::User.create(
      email: params[:email],
      password: params[:password],
      name: params[:name]
    )
    session[:user_id] = user.id
    redirect '/'
  rescue => e
    @error = 'アカウント作成に失敗しました: ' + e.message
    erb :signup
  end
end

get '/logout' do
  session.clear
  redirect '/'
end

# マイページ
get '/mypage' do
  require_login!
  saved_recipes = current_user.saved_recipes.map(&:to_h)
  viewed_recipes = current_user.viewed_recipes.take(10).map(&:to_h)

  erb :mypage, locals: {
    user: current_user.to_h,
    saved_recipes: saved_recipes,
    viewed_recipes: viewed_recipes
  }
end

# ========== API ルート ==========

# レシピ一覧 API
get '/api/recipes' do
  query = params[:q]
  industry = params[:industry]
  difficulty = params[:difficulty]
  limit = (params[:limit] || 20).to_i
  offset = (params[:offset] || 0).to_i

  recipes = Models::Recipe.search(
    query: query,
    industry: industry,
    difficulty: difficulty,
    limit: limit,
    offset: offset
  )

  json_response({
    recipes: recipes.map(&:to_h),
    total: recipes.length,
    limit: limit,
    offset: offset
  })
end

# レシピ詳細 API
get '/api/recipes/:id' do
  recipe = Models::Recipe.find(params[:id])
  halt 404, json_response({ error: 'Recipe not found' }, 404) unless recipe

  steps = recipe.steps.map(&:to_h)
  tags = recipe.tags.map(&:to_h)

  json_response({
    recipe: recipe.to_h,
    steps: steps,
    tags: tags
  })
end

# 人気レシピ API
get '/api/recipes/popular' do
  limit = (params[:limit] || 10).to_i
  recipes = Models::Recipe.popular(limit)

  json_response({
    recipes: recipes.map(&:to_h)
  })
end

# ユーザー登録 API
post '/api/auth/signup' do
  request.body.rewind
  data = JSON.parse(request.body.read)

  begin
    user = Models::User.create(
      email: data['email'],
      password: data['password'],
      name: data['name']
    )
    session[:user_id] = user.id

    json_response({
      user: user.to_h,
      message: 'アカウントが作成されました'
    }, 201)
  rescue => e
    json_response({
      error: 'アカウント作成に失敗しました',
      details: e.message
    }, 400)
  end
end

# ログイン API
post '/api/auth/login' do
  request.body.rewind
  data = JSON.parse(request.body.read)

  user = Models::User.authenticate(data['email'], data['password'])

  if user
    session[:user_id] = user.id
    json_response({
      user: user.to_h,
      message: 'ログインしました'
    })
  else
    json_response({
      error: 'メールアドレスまたはパスワードが正しくありません'
    }, 401)
  end
end

# ログアウト API
post '/api/auth/logout' do
  session.clear
  json_response({ message: 'ログアウトしました' })
end

# 現在のユーザー情報 API
get '/api/auth/me' do
  if logged_in?
    json_response({ user: current_user.to_h })
  else
    json_response({ user: nil })
  end
end

# レシピ保存 API
post '/api/recipes/:id/save' do
  require_login!

  recipe = Models::Recipe.find(params[:id])
  halt 404, json_response({ error: 'Recipe not found' }, 404) unless recipe

  action = Models::UserAction.record(
    user_id: current_user.id,
    recipe_id: recipe.id,
    action_type: 'save'
  )

  json_response({
    message: 'レシピを保存しました',
    action: action.to_h
  })
end

# レシピ保存解除 API
delete '/api/recipes/:id/save' do
  require_login!

  Models::UserAction.db.execute(
    "DELETE FROM user_actions WHERE user_id = ? AND recipe_id = ? AND action_type = 'save'",
    [current_user.id, params[:id]]
  )

  # save_countを減らす
  Models::Recipe.db.execute(
    "UPDATE recipes SET save_count = CASE WHEN save_count > 0 THEN save_count - 1 ELSE 0 END WHERE id = ?",
    [params[:id]]
  )

  json_response({ message: 'レシピの保存を解除しました' })
end

# レシピ評価 API
post '/api/recipes/:id/rate' do
  require_login!
  request.body.rewind
  data = JSON.parse(request.body.read)

  recipe = Models::Recipe.find(params[:id])
  halt 404, json_response({ error: 'Recipe not found' }, 404) unless recipe

  rating = data['rating'].to_i
  halt 400, json_response({ error: '評価は1-5の範囲で指定してください' }, 400) unless (1..5).include?(rating)

  action = Models::UserAction.record(
    user_id: current_user.id,
    recipe_id: recipe.id,
    action_type: 'rate',
    rating: rating,
    comment: data['comment']
  )

  json_response({
    message: 'レシピを評価しました',
    action: action.to_h
  })
end

# 視聴記録 API
post '/api/recipes/:id/view' do
  require_login!
  request.body.rewind
  data = JSON.parse(request.body.read)

  recipe = Models::Recipe.find(params[:id])
  halt 404, json_response({ error: 'Recipe not found' }, 404) unless recipe

  action = Models::UserAction.record(
    user_id: current_user.id,
    recipe_id: recipe.id,
    action_type: 'view',
    progress_seconds: data['progress_seconds']
  )

  json_response({
    message: '視聴記録を保存しました',
    action: action.to_h
  })
end

# タグ一覧 API
get '/api/tags' do
  tags = Models::Tag.all
  json_response({ tags: tags.map(&:to_h) })
end

# タグ別レシピ API
get '/api/tags/:id/recipes' do
  tag = Models::Tag.find(params[:id])
  halt 404, json_response({ error: 'Tag not found' }, 404) unless tag

  recipes = tag.recipes.map(&:to_h)
  json_response({
    tag: tag.to_h,
    recipes: recipes
  })
end

# ========== 管理画面ルート ==========

get '/admin' do
  recipes = Models::Recipe.all
  erb :admin, locals: { recipes: recipes.map(&:to_h) }
end

# ========== エラーハンドリング ==========

not_found do
  if request.path.start_with?('/api/')
    json_response({ error: 'Not found' }, 404)
  else
    erb :not_found
  end
end

error do
  if request.path.start_with?('/api/')
    json_response({ error: 'Internal server error' }, 500)
  else
    erb :error
  end
end

# ========== サーバー起動 ==========

if __FILE__ == $0
  # シードデータ投入（初回のみ）
  if Models::Recipe.all.empty?
    puts "📦 シードデータを投入中..."
    Database.seed!
  end

  port = settings.port
  puts "\n" + "="*50
  puts "🚀 ミーネクストサーバーが起動しました"
  puts "="*50
  puts "📍 トップページ:    http://localhost:#{port}"
  puts "👤 ログイン:        http://localhost:#{port}/login"
  puts "📝 サインアップ:    http://localhost:#{port}/signup"
  puts "⚙️  管理画面:        http://localhost:#{port}/admin"
  puts "🔌 API:             http://localhost:#{port}/api/recipes"
  puts "="*50
  puts "\n✨ 開発を楽しんでください！\n\n"
end
