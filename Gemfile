source 'https://rubygems.org'

# Specify your gem's dependencies in devise_saml_authenticatable.gemspec
gemspec

group :test do
  gem 'rake'
  gem 'rspec', '~> 3.0'
  gem 'rails', '~> 7.1.0'
  gem 'rspec-rails'
  gem 'sqlite3', '~> 1.4'
  gem 'capybara'
  gem 'selenium-webdriver'

  if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new("3.0")
    gem 'webrick'
  end

  if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new("3.1")
    gem 'net-smtp', require: false
    gem 'net-imap', require: false
    gem 'net-pop', require: false
  end
end
