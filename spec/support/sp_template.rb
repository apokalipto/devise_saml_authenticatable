# Set up a SAML Service Provider

require "onelogin/ruby-saml/version"

saml_session_index_key = ENV.fetch('SAML_SESSION_INDEX_KEY', ":session_index")
use_subject_to_authenticate = ENV.fetch('USE_SUBJECT_TO_AUTHENTICATE')
idp_settings_adapter = ENV.fetch('IDP_SETTINGS_ADAPTER', "nil")
idp_entity_id_reader = ENV.fetch('IDP_ENTITY_ID_READER', "DeviseSamlAuthenticatable::DefaultIdpEntityIdReader")
saml_failed_callback = ENV.fetch('SAML_FAILED_CALLBACK', "nil")

gsub_file 'config/secrets.yml', /secret_key_base:.*$/, 'secret_key_base: "8b5889df1fcf03f76c7d66da02d8776bcc85b06bed7d9c592f076d9c8a5455ee6d4beae45986c3c030b40208db5e612f2a6ef8283036a352e3fae83c5eda36be"'

gem 'devise_saml_authenticatable', path: '../../..'
gem 'ruby-saml', OneLogin::RubySaml::VERSION
gem 'thin'

insert_into_file('Gemfile', after: /\z/) {
  <<-GEMFILE
# Lock down versions of gems for older versions of Ruby
if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new("2.1")
  gem 'devise', '~> 3.5'
  gem 'nokogiri', '~> 1.6.8'
end
  GEMFILE
}

template File.expand_path('../idp_settings_adapter.rb.erb', __FILE__), 'app/lib/idp_settings_adapter.rb'

create_file 'config/attribute-map.yml', <<-ATTRIBUTES
---
"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress": email
"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name":         name
ATTRIBUTES

create_file('app/lib/our_saml_failed_callback_handler.rb', <<-CALLBACKHANDLER)

class OurSamlFailedCallbackHandler
  def handle(response, strategy)
    strategy.redirect! "http://www.example.com"
  end
end
CALLBACKHANDLER

create_file('app/lib/our_entity_id_reader.rb', <<-READER)

class OurEntityIdReader
  def self.entity_id(params)
    if params[:entity_id]
      params[:entity_id]
    elsif params[:SAMLRequest]
      OneLogin::RubySaml::SloLogoutrequest.new(params[:SAMLRequest]).issuer
    elsif params[:SAMLResponse]
      OneLogin::RubySaml::Response.new(params[:SAMLResponse]).issuers.first
    else
      "http://www.cats.com"
    end
  end
end
READER

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
  config.secret_key = 'adc7cd73792f5d20055a0ac749ce8cdddb2e0f0d3ea7fe7855eec3d0f81833b9a4ac31d12e05f232d40ae86ca492826a6fc5a65228c6e16752815316e2d5b38d'

  config.saml_default_user_key = :email
  config.saml_session_index_key = #{saml_session_index_key}

  config.saml_use_subject = #{use_subject_to_authenticate}
  config.saml_create_user = true
  config.saml_update_user = true
  config.idp_settings_adapter = #{idp_settings_adapter}
  config.idp_entity_id_reader = #{idp_entity_id_reader}
  config.saml_failed_callback = #{saml_failed_callback}

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
  skip_before_action :verify_authenticity_token
  def create
    User.create!(email: params[:email])
    render nothing: true, status: 201
  end
end
  USERS

  rake "db:create"
  rake "db:migrate"
  rake "db:create", env: "production"
  rake "db:migrate", env: "production"
end

create_file 'public/stylesheets/application.css', ''
