module DeviseSamlAuthenticatable
  class DefaultIdpEntityIdReader
    def self.entity_id(params)
      if params[:SAMLRequest]
        OneLogin::RubySaml::SloLogoutrequest.new(params[:SAMLRequest]).issuer
      elsif params[:SAMLResponse]
        OneLogin::RubySaml::Response.new(params[:SAMLResponse]).issuers.first
      end
    end
  end
end
