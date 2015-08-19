require 'devise/strategies/authenticatable' 
module Devise
  module Strategies
    class SamlAuthenticatable < Authenticatable
      include DeviseSamlAuthenticatable::SamlConfig
      def valid?
        if params[:SAMLResponse]
          response = OneLogin::RubySaml::Logoutresponse.new(params[:SAMLResponse], get_saml_config)
          !(response.response.include? 'LogoutResponse')
        else
          false
        end
      end

      def authenticate!
        @response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], settings: get_saml_config)
        resource = mapping.to.authenticate_with_saml(@response)
        if @response.is_valid?
          resource.after_saml_authentication(@response.sessionindex)
          success!(resource)
        else
          fail!(:invalid)
        end
      end

      # This method should turn off storage whenever CSRF cannot be verified.
      # Any known way on how to let the IdP send the CSRF token along with the SAMLResponse ?
      # Please let me know!
      def store?
        true
      end

    end
  end
end

Warden::Strategies.add(:saml_authenticatable, Devise::Strategies::SamlAuthenticatable)
