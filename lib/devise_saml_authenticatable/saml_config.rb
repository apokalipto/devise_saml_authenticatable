require 'ruby-saml'
module DeviseSamlAuthenticatable
  module SamlConfig
    def get_saml_config
      idp_config_path = "#{Rails.root}/config/idp.yml"
      # Support 0.0.x-style configuration via a YAML file
      if File.exists?(idp_config_path)
        Devise.saml_config = OneLogin::RubySaml::Settings.new(YAML.load(File.read(idp_config_path))[Rails.env])
      end

      @saml_config = Devise.saml_config
    end
  end
end
