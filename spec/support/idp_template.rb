# Set up a SAML IdP

@include_subject_in_attributes = ENV.fetch('INCLUDE_SUBJECT_IN_ATTRIBUTES')
@valid_destination = ENV.fetch('VALID_DESTINATION', "true")

gsub_file 'config/secrets.yml', /secret_key_base:.*$/, 'secret_key_base: "34814fd41f91c493b89aa01ac73c44d241a31245b5bc5542fa4b7317525e1dcfa60ba947b3d085e4e229456fdee0d8af6aac6a63cf750d807ea6fe5d853dff4a"'

gem 'ruby-saml-idp'
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

route "get '/saml/auth' => 'saml_idp#new'"
route "post '/saml/auth' => 'saml_idp#create'"
route "get '/saml/logout' => 'saml_idp#logout'"
route "get '/saml/sp_sign_out' => 'saml_idp#sp_sign_out'"

template File.expand_path('../saml_idp_controller.rb.erb', __FILE__), 'app/controllers/saml_idp_controller.rb'

copy_file File.expand_path('../saml_idp-saml_slo_post.html.erb', __FILE__), 'app/views/saml_idp/saml_slo_post.html.erb'
create_file 'public/stylesheets/application.css', ''

gsub_file 'config/application.rb', /end[\n\w]*end$/, <<-CONFIG
    config.slo_sp_url = "http://localhost:8020/users/saml/idp_sign_out"
  end
end
CONFIG
