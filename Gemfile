source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

ruby '2.5.0'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.5'
#ruby-gemset=payment_atm

# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 3.7'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Bootstrap 4 Ruby Gem for Rails / Sprockets and Compass. 
gem 'bootstrap'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Flexible authentication solution for Rails with Warden. 
gem 'devise'

# Use haml views
gem 'haml'
gem 'haml-rails'

gem 'jquery-rails'

# Font-Awesome Sass gem for use in Ruby/Rails projects
gem 'font-awesome-sass'

# Set environment variables within application.yml
gem "figaro"

# Connect to MS SQL Database
gem 'tiny_tds' 
gem 'activerecord-sqlserver-adapter', :github => 'rails-sqlserver/activerecord-sqlserver-adapter', :branch => 'master'

# Do some browser detection with Ruby. Includes ActionController integration.
gem 'browser'

gem 'simple_form'

# SOAP calls to EZcash web services
gem 'savon'

# Pagination: https://github.com/amatsuda/kaminari
gem 'kaminari'

# Authorization
gem 'cancancan'

# https://github.com/Nerian/bootstrap-datepicker-rails
gem 'bootstrap-datepicker-rails'

# Chart.js for Rails Asset Pipeline
gem 'chart-js-rails'

# Provide a clear syntax for writing and deploying cron jobs.
gem 'whenever', :require => false

# Exception notifications
gem 'exception_notification'


# File uploads
gem 'carrierwave'

# Creating barcodes
gem 'barby'
gem 'rqrcode'

# Phone
gem 'twilio-ruby'

# Dynamically add and remove nested has_many association fields in a Ruby on Rails form
gem 'nested_form_fields'

# Background jobs
gem 'sidekiq'
# For sidekiq web UI
gem 'sinatra', github: 'sinatra/sinatra', require: false
gem 'rack-protection'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
