require "devise"

require "devise_saml_authenticatable/version"
require "devise_saml_authenticatable/exception"
require "devise_saml_authenticatable/logger"
require "devise_saml_authenticatable/routes"
require "devise_saml_authenticatable/saml_config"

begin
  Rails::Engine
rescue
else
  module DeviseSamlAuthenticatable
    class Engine < Rails::Engine
    end
  end
end

# Get saml information from config/saml.yml now
module Devise
  # Allow logging
  mattr_accessor :saml_logger
  @@saml_logger = true

  # Add valid users to database
  mattr_accessor :saml_create_user
  @@saml_create_user = false

  mattr_accessor :saml_default_user_key
  @@saml_default_user_key

  mattr_accessor :saml_use_subject
  @@saml_use_subject

  mattr_accessor :saml_session_index_key
  @@saml_session_index_key

  mattr_accessor :saml_config
  @@saml_config = OneLogin::RubySaml::Settings.new
  def self.saml_configure
    yield saml_config
  end
end

# Add saml_authenticatable strategy to defaults.
#
Devise.add_module(:saml_authenticatable,
                  :route => :saml_authenticatable, 
                  :strategy   => true,
                  :controller => :saml_sessions,
                  :model  => 'devise_saml_authenticatable/model')


