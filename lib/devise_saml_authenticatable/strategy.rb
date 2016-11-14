require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class SamlAuthenticatable < Authenticatable
      include DeviseSamlAuthenticatable::SamlConfig
      def valid?
        if params[:SAMLResponse]
          OneLogin::RubySaml::Response.new(params[:SAMLResponse], settings: saml_config(get_idp_entity_id(params)), allowed_clock_drift: (Devise.allowed_clock_drift_in_seconds || nil))
        else
          false
        end
      end

      def authenticate!
        parse_saml_response
        retrieve_resource unless self.halted?
        unless self.halted?
          @resource.after_saml_authentication(@response.sessionindex)
          success!(@resource)
        end
      end

      # This method should turn off storage whenever CSRF cannot be verified.
      # Any known way on how to let the IdP send the CSRF token along with the SAMLResponse ?
      # Please let me know!
      def store?
        !mapping.to.skip_session_storage.include?(:saml_auth)
      end

      private
      def parse_saml_response
        @response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], settings: saml_config(get_idp_entity_id(params)), allowed_clock_drift: (Devise.allowed_clock_drift_in_seconds || nil))
        unless @response.is_valid?
          failed_auth("Auth errors: #{@response.errors.join(', ')}")
        end
      end

      def retrieve_resource
        @resource = mapping.to.authenticate_with_saml(@response, params[:RelayState])
        if @resource.nil?
          failed_auth("Resource could not be found")
        end
      end

      def failed_auth(msg)
        DeviseSamlAuthenticatable::Logger.send(msg)
        fail!(:invalid)
        Devise.saml_failed_callback.new.handle(@response, self) if Devise.saml_failed_callback
      end

    end
  end
end

Warden::Strategies.add(:saml_authenticatable, Devise::Strategies::SamlAuthenticatable)
