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

  protected

  # Override devise to send user to IdP logout for SLO
  def after_sign_out_path_for(_)
    request = OneLogin::RubySaml::Logoutrequest.new
    request.create(@saml_config)
  end
end

