# Set up a SAML IdP

gem 'ruby-saml-idp'

route "get '/saml/auth' => 'saml_idp#new'"
route "post '/saml/auth' => 'saml_idp#create'"

create_file 'app/controllers/saml_idp_controller.rb', File.read(File.expand_path('../saml_idp_controller.rb', __FILE__))
