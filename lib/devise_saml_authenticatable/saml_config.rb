require 'ruby-saml'
module DeviseSamlAuthenticatable
  module SamlConfig
    def saml_config
      return file_based_config if file_based_config

      Devise.saml_config
    end

    private

    def file_based_config
      return @file_based_config if @file_based_config
      idp_config_path = "#{Rails.root}/config/idp.yml"

      if File.exists?(idp_config_path)
        @file_based_config ||= Devise.saml_config = OneLogin::RubySaml::Settings.new(YAML.load(File.read(idp_config_path))[Rails.env])
      end
    end
  end
end
