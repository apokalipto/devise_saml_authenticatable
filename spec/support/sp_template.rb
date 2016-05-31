# Set up a SAML Service Provider

saml_session_index_key = ENV.fetch('SAML_SESSION_INDEX_KEY', ":session_index")
use_subject_to_authenticate = ENV.fetch('USE_SUBJECT_TO_AUTHENTICATE')

gem 'devise_saml_authenticatable', path: '../../..'
gem 'thin'

insert_into_file('Gemfile', after: /\z/) {
  <<-GEMFILE
# Lock down versions of gems for older versions of Ruby
if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new("2.0")
  gem 'mime-types', '~> 2.99'
end
if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new("2.1")
  gem 'devise', '~> 3.5'
end
  GEMFILE
}

create_file 'config/attribute-map.yml', <<-ATTRIBUTES
---
"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress": email
"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name":         name
ATTRIBUTES

after_bundle do
  generate :controller, 'home', 'index'
  insert_into_file('app/controllers/home_controller.rb', after: "class HomeController < ApplicationController\n") {
    <<-AUTHENTICATE
    before_action :authenticate_user!
    AUTHENTICATE
  }
  insert_into_file('app/views/home/index.html.erb', after: /\z/) {
    <<-HOME
<%= current_user.email %> <%= current_user.name %>
<%= form_tag destroy_user_session_path, method: :delete do %>
  <%= submit_tag "Log out" %>
<% end %>
    HOME
  }
  route "root to: 'home#index'"

  # Configure for our SAML IdP
  generate 'devise:install'
  gsub_file 'config/initializers/devise.rb', /^end$/, <<-CONFIG
  config.saml_default_user_key = :email
  config.saml_session_index_key = #{saml_session_index_key}

  config.saml_use_subject = #{use_subject_to_authenticate}
  config.saml_create_user = true
  config.saml_update_user = true

  config.saml_configure do |settings|
    settings.assertion_consumer_service_url = "http://localhost:8020/users/saml/auth"
    settings.issuer = "http://localhost:8020/saml/metadata"
    settings.idp_slo_target_url = "http://localhost:8009/saml/logout"
    settings.idp_sso_target_url = "http://localhost:8009/saml/auth"
    settings.idp_cert_fingerprint = "9E:65:2E:03:06:8D:80:F2:86:C7:6C:77:A1:D9:14:97:0A:4D:F4:4D"
  end
end
  CONFIG

  generate :devise, "user", "email:string", "name:string", "session_index:string"
  gsub_file 'app/models/user.rb', /database_authenticatable.*\n.*/, 'saml_authenticatable'
  route "resources :users, only: [:create]"
  create_file('app/controllers/users_controller.rb', <<-USERS)
class UsersController < ApplicationController
  skip_before_filter :verify_authenticity_token
  def create
    User.create!(email: params[:email])
    render nothing: true, status: 201
  end
end
  USERS

  rake "db:create"
  rake "db:migrate"
end

create_file 'public/stylesheets/application.css', ''
