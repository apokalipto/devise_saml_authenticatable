# Set up a SAML IdP

gem 'ruby-saml-idp'

route "get '/saml/auth' => 'saml_idp#new'"
route "post '/saml/auth' => 'saml_idp#create'"

create_file 'app/controllers/saml_idp_controller.rb', <<-CONTROLLER
class SamlIdpController < SamlIdp::IdpController
  def idp_authenticate(email, password)
    true
  end

  def idp_make_saml_response(user)
    encode_SAMLResponse("you@example.com")
  end
end
CONTROLLER
