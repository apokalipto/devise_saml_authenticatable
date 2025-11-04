module DeviseSamlAuthenticatable
  class DefaultIdpEntityIdReader
    def self.entity_id(params)
      if params[:SAMLRequest]
        OneLogin::RubySaml::SloLogoutrequest.new(
          params[:SAMLRequest],
          settings: Devise.saml_config,
          allowed_clock_drift: Devise.allowed_clock_drift_in_seconds,
        ).issuer
      elsif params[:SAMLResponse]
        response = OneLogin::RubySaml::Response.new(params[:SAMLResponse],
            settings: Devise.saml_config,
            allowed_clock_drift: Devise.allowed_clock_drift_in_seconds,
          )
        doc = REXML::Document.new(response.response)

        if REXML::XPath.match(doc,"/p:LogoutResponse",{ "p" => OneLogin::RubySaml::SamlMessage::PROTOCOL}).any?
          REXML::XPath.match(doc,"/p:LogoutResponse/a:Issuer",{ "p" => OneLogin::RubySaml::SamlMessage::PROTOCOL, "a" => OneLogin::RubySaml::SamlMessage::ASSERTION }).first.text
        else
          response.issuers.first
        end
      end
    end
  end
end
