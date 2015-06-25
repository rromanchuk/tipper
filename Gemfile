source 'https://rubygems.org'

ruby '2.2.2'

gem 'rails', '4.2.2'

# Use SCSS for stylesheets
gem 'sass-rails', '>= 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '>= 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '>= 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'aws-sdk'
gem 'responders', github: "plataformatec/responders"
gem 'bootstrap-sass', '>= 3.3.3'
gem 'bitcoin-client', github: "rromanchuk/bitcoin-client"
gem 'stripe', :git => 'https://github.com/stripe/stripe-ruby'
gem "slim-rails"
gem "twitter"
gem "satoshi-unit"
gem "bugsnag"
gem 'newrelic_rpm'
gem 'eventmachine'
gem 'money'
gem 'monetize'
gem 'foreman'
gem 'remote_syslog_logger'
gem "aws-ses", :require => 'aws/ses'
gem 'premailer-rails'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
group :development do
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'letter_opener_web'
end

gem 'puma'
gem 'dotenv', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'
end
