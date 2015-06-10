# Set up a SAML IdP

include_subject_in_attributes = ask("Include the subject in the attributes?", limit: %w(y n)) == "y"

gem 'ruby-saml-idp'

route "get '/saml/auth' => 'saml_idp#new'"
route "post '/saml/auth' => 'saml_idp#create'"

saml_idp_controller_template = File.read(File.expand_path('../saml_idp_controller.rb.erb', __FILE__))
saml_idp_controller_contents = ERB.new(saml_idp_controller_template).result(binding)
create_file 'app/controllers/saml_idp_controller.rb', saml_idp_controller_contents
