require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class SamlAuthenticatable < Authenticatable
      include DeviseSamlAuthenticatable::SamlConfig
      def valid?
        params[:SAMLResponse]
      end

      def authenticate!
        @response = OneLogin::RubySaml::Response.new(params[:SAMLResponse])
        @response.settings = get_saml_config
        resource = mapping.to.authenticate_with_saml(@response.attributes)

        if @response.is_valid?
          success!(resource)
        else
          fail!(:invalid)
        end
      end

      # This method should turn off storage whenever CSRF cannot be verified.
      # Any known way on how to let the IdP send the CSRF token along with the
      # SAMLResponse? Please let me know!
      def store?
        true
      end
    end
  end
end

Warden::Strategies.add(:saml_authenticatable,
                       Devise::Strategies::SamlAuthenticatable)
