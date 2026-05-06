module DeviseSamlAuthenticatable
  class DefaultIdpEntityIdReader
    def self.entity_id(params)
      if params[:SAMLRequest]
        ::RubySaml::SloLogoutrequest.new(
          params[:SAMLRequest],
          settings: Devise.saml_config,
          allowed_clock_drift: Devise.allowed_clock_drift_in_seconds,
        ).issuer
      elsif params[:SAMLResponse]
        ::RubySaml::Response.new(
          params[:SAMLResponse],
          settings: Devise.saml_config,
          allowed_clock_drift: Devise.allowed_clock_drift_in_seconds,
        ).issuers.first
      end
    end
  end
end
