# Set up a SAML Service Provider

gem 'devise_saml_authenticatable', path: '../../..'

generate :controller, 'home', 'index'
insert_into_file('app/controllers/home_controller.rb', after: "class HomeController < ApplicationController\n") {
  <<-AUTHENTICATE
  before_action :authenticate_user!
  AUTHENTICATE
}
route "root to: 'home#index'"

create_file 'config/idp.yml', <<-IDP
---
development: &development
  assertion_consumer_service_url: http://localhost:8020/users/saml/auth
  issuer: http://localhost:8020/saml/metadata
  idp_sso_target_url: http://localhost:8009/saml/auth
  idp_cert_fingerprint: "9E:65:2E:03:06:8D:80:F2:86:C7:6C:77:A1:D9:14:97:0A:4D:F4:4D"

test:
  <<: *development
IDP

create_file 'config/attribute-map.yml', <<-ATTRIBUTES
---
"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress": email
ATTRIBUTES

after_bundle do
  # Configure for our SAML IdP
  generate 'devise:install'
  gsub_file 'config/initializers/devise.rb', /^end$/, <<-CONFIG
  config.saml_default_user_key = :email
end
  CONFIG

  generate :devise, "user", "email:string"
  gsub_file 'app/models/user.rb', /database_authenticatable.*\n.*/, 'saml_authenticatable'

  insert_into_file('db/seeds.rb', before: /\z/) {
    <<-USER
User.find_or_create_by!(email: "you@example.com")
    USER
  }

  rake "db:create"
  rake "db:migrate"
  rake "db:seed"
end
