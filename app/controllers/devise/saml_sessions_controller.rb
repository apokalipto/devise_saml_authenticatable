require 'ruby-saml'

module Devise
  class SamlSessionsController < Devise::SessionsController
    include DeviseSamlAuthenticatable::SamlConfig

    unloadable if Rails::VERSION::MAJOR < 4
    before_filter :get_saml_config

    def new
      request = OneLogin::RubySaml::Authrequest.new
      action = request.create(@saml_config)
      redirect_to action
    end

    def metadata
      meta = OneLogin::RubySaml::Metadata.new
      render xml: meta.generate(@saml_config)
    end
  end
end
