source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.6'

gem 'rails', '~> 7.0.0'
gem 'pg', '~> 1.1'
gem 'puma', '~> 5.0'
gem 'sass-rails', '>= 6'
# gem 'webpacker', '~> 5.0' # Rails 8.0では不要
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'jbuilder', '~> 2.7'
gem 'bootsnap', '>= 1.4.4', require: false
gem 'image_processing', '~> 1.2'

# Authentication
gem 'devise'

# AWS & Video Processing
gem 'aws-sdk-s3', '~> 1.0'
gem 'aws-sdk-cloudfront', '~> 1.0'
gem 'streamio-ffmpeg'

# API
gem 'rack-cors'

# Admin Interface
gem 'rails_admin', '~> 3.0'
gem 'sassc-rails'

# Background Jobs
gem 'sidekiq'

# Simple web server
gem 'sinatra'
gem 'sinatra-contrib'
gem 'sqlite3', '>= 2.1'
gem 'bcrypt', '~> 3.1'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'web-console', '>= 4.1.0'
  gem 'listen', '~> 3.3'
  gem 'spring'
end