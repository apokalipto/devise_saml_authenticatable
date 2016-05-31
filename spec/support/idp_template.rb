# Set up a SAML IdP

@include_subject_in_attributes = ENV.fetch('INCLUDE_SUBJECT_IN_ATTRIBUTES')

gem 'ruby-saml-idp'
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
