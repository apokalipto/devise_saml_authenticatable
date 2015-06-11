# Set up a SAML IdP

@include_subject_in_attributes = ask("Include the subject in the attributes?", limit: %w(y n)) == "y"

gem 'ruby-saml-idp'

route "get '/saml/auth' => 'saml_idp#new'"
route "post '/saml/auth' => 'saml_idp#create'"

template File.expand_path('../saml_idp_controller.rb.erb', __FILE__), 'app/controllers/saml_idp_controller.rb'
