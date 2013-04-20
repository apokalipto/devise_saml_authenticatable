require "ruby-saml"

class Devise::SamlSessionsController < Devise::SessionsController
  include DeviseSamlAuthenticatable::SamlConfig
  unloadable
  before_filter :get_saml_config
  def new
    resource = build_resource
    request = Onelogin::Saml::Authrequest.new
    action = request.create(@saml_config)
    redirect_to action
  end
      
  def metadata
    meta = Onelogin::Saml::Metadata.new
    render :xml => meta.generate(@saml_config)
  end
  
end

