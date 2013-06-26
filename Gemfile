source 'https://rubygems.org'

gem 'rails', '4.0.0'

gem 'pg'
gem 'will_paginate'
gem 'cancan'
gem 'role_model'
gem 'paper_trail', github: 'airblade/paper_trail', branch: 'rails4'
gem 'magick_columns', github: 'kainlite/magick_columns'
gem 'simple_form', '~> 3.0.0.rc'
gem 'devise', '~> 3.0.0.rc'
gem 'validates_timeliness'
gem 'sidekiq'
gem 'capistrano'
gem 'activeresource', '4.0.0', require: 'active_resource'

gem 'coveralls', require: false

# Assets Group =)
gem 'sass-rails', '~> 4.0.0'
gem 'coffee-rails'
gem 'uglifier'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'turbolinks'

group :development do
  gem 'unicorn'
  gem 'unicorn-rails'
end

group :test do
  gem 'turn'
  gem 'selenium-webdriver', require: false
  gem 'capybara', require: false
  gem 'database_cleaner' # For Capybara
  gem 'fabrication'
  gem 'faker'
  gem 'webmock'
end

if ENV['TRAVIS']
  gem 'test-unit' # For Travis errors
end
