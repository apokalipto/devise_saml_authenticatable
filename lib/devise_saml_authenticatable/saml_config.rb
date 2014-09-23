require 'ruby-saml'
module DeviseSamlAuthenticatable
  module SamlConfig
    def saml_settings
      config_file_path = "#{Rails.root}/config/idp.yml"
      config_file = YAML.load(File.read(config_file_path))[Rails.env]
      @saml_config ||= OneLogin::RubySaml::Settings.new(config_file)
    end

    def attribute_map
      attr_file_path = "#{Rails.root}/config/attribute-map.yml"
      @attribute_map ||= YAML.load(File.read(attr_file_path))
    end
  end
end
