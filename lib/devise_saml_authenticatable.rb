require "devise"

require "devise_saml_authenticatable/version"
require "devise_saml_authenticatable/exception"
require "devise_saml_authenticatable/logger"
require "devise_saml_authenticatable/routes"
require "devise_saml_authenticatable/saml_config"
require "devise_saml_authenticatable/default_idp_entity_id_reader"

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

  # Update user attributes after login
  mattr_accessor :saml_update_user
  @@saml_update_user = false

  mattr_accessor :saml_default_user_key
  @@saml_default_user_key

  mattr_accessor :saml_use_subject
  @@saml_use_subject

  # Key used to index sessions for later retrieval
  mattr_accessor :saml_session_index_key
  @@saml_session_index_key

  # Redirect after signout (redirects to 'users/saml/sign_in' by default)
  mattr_accessor :saml_sign_out_success_url
  @@saml_sign_out_success_url

  # Adapter for multiple IdP support
  mattr_accessor :idp_settings_adapter
  @@idp_settings_adapter

  # Reader that can parse entity id from a SAMLMessage
  mattr_accessor :idp_entity_id_reader
  @@idp_entity_id_reader ||= ::DeviseSamlAuthenticatable::DefaultIdpEntityIdReader

  # Implements a #handle method that takes the response and strategy as an argument
  mattr_accessor :saml_failed_callback
  @@saml_failed_callback

  # lambda that generates the RelayState param for the SAML AuthRequest, takes request
  # from SamlSessionsController#new action as an argument
  mattr_accessor :saml_relay_state
  @@saml_relay_state

  # Instead of storing the attribute_map in attribute-map.yml, store it in the database, or set it programatically ...
  mattr_accessor :attribute_map
  @@attribute_map

  # Allow a block to be passed, to replace `set_user_saml_attributes` -- allowing more
  # control over how the attributes are assigned to the user
  mattr_accessor :set_user_saml_attributes_custom_function
  @@set_user_saml_attributes_custom_function
  
  # Pass in a custom value for allowed_clock_drift
  mattr_accessor :allowed_clock_drift_in_seconds
  @@allowed_clock_drift_in_seconds

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
