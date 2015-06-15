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

  def destroy
    if @saml_config.assertion_consumer_logout_service_url
      # Assume the SP is handling sign out at their logout ACS URL
      warden.session(resource_name)[:logout_request_id] = logout_request.uuid
      # Respond just like `super`, but without signing out
      respond_to do |format|
        format.all { head :no_content }
        format.any(*navigational_formats) { redirect_to after_sign_out_path_for(resource_name) }
      end
    else
      super
    end
  end

  protected

  def logout_request
    @request ||= OneLogin::RubySaml::Logoutrequest.new
  end

  # Override devise to send user to IdP logout for SLO
  def after_sign_out_path_for(_)
    logout_request.create(@saml_config)
  end
end

