require 'ruby-saml'

module DeviseSamlAuthenticatable
  module SamlConfig
    def get_saml_config
      yaml_file = File.read("#{Rails.root}/config/idp.yml")
      yaml_config = YAML.load(yaml_file)[Rails.env]

      @saml_config = OneLogin::RubySaml::Settings.new(yaml_config)
    end
  end
end
