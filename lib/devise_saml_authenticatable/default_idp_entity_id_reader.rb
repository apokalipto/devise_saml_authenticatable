module DeviseSamlAuthenticatable
  class DefaultIdpEntityIdReader
    def self.entity_id(params)
      if params[:SAMLRequest]
        OneLogin::RubySaml::SloLogoutrequest.new(params[:SAMLRequest], allowed_clock_drift: (Devise.allowed_clock_drift_in_seconds || nil)).issuer
      elsif params[:SAMLResponse]
        OneLogin::RubySaml::Response.new(params[:SAMLResponse], allowed_clock_drift: (Devise.allowed_clock_drift_in_seconds || nil)).issuers.first
      end
    end
  end
end
