source 'https://rubygems.org'

# Specify your gem's dependencies in devise_saml_authenticatable.gemspec
gemspec

group :test do
  gem 'rake'
  gem 'rspec', '~> 3.0'
  gem 'rails', '~> 5.2'
  gem 'rspec-rails'
  gem 'sqlite3', '~> 1.3.6'
  gem 'capybara'
  gem 'poltergeist'

  # Lock down versions of gems for older versions of Ruby
  if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new("2.4")
    gem 'responders', '~> 2.4'
  end
end
