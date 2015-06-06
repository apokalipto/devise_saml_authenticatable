require 'ruby-saml'
module DeviseSamlAuthenticatable
  module SamlConfig
    IDP_CONFIG_PATH = "#{Rails.root}/config/idp.yml"

    def get_saml_config
      # Support 0.0.x-style configuration via a YAML file
      if File.exists?(IDP_CONFIG_PATH)
        Devise.saml_config = OneLogin::RubySaml::Settings.new(YAML.load(File.read(IDP_CONFIG_PATH))[Rails.env])
      end

      @saml_config = Devise.saml_config
    end
  end
end
