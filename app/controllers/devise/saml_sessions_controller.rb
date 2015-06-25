require "ruby-saml"

class Devise::SamlSessionsController < Devise::SessionsController
  include DeviseSamlAuthenticatable::SamlConfig
  unloadable if Rails::VERSION::MAJOR < 4
  before_filter :get_saml_config
  skip_before_filter :verify_authenticity_token

  def new
    request = OneLogin::RubySaml::Authrequest.new
    action = request.create(@saml_config)
    redirect_to action
  end
      
  def metadata
    meta = OneLogin::RubySaml::Metadata.new
    render :xml => meta.generate(@saml_config)
  end

  def idp_sign_out
    if params[:SAMLRequest] && Devise.saml_session_index_key
      logout_request = SamlSloLogoutrequest.new(params[:SAMLRequest], @saml_config)
      logout_request.session_indexes.each do |session_index|
        resource_class.reset_session_key_for(session_index)
      end

      redirect_to generate_idp_logout_response(logout_request)
    else
      head :invalid_request
    end
  end

  protected

  # Override devise to send user to IdP logout for SLO
  def after_sign_out_path_for(_)
    request = OneLogin::RubySaml::Logoutrequest.new
    request.create(@saml_config)
  end

  def generate_idp_logout_response(logout_request)
    logout_request_id = logout_request.id
    OneLogin::RubySaml::SloLogoutresponse.new.create(@saml_config, logout_request_id, nil)
  end
end

