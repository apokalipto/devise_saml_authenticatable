require 'ruby-saml'
module DeviseSamlAuthenticatable
  module SamlConfig
    def get_saml_config
      @saml_config = OneLogin::RubySaml::Settings.new(YAML.load(File.read("#{Rails.root}/config/idp.yml"))[Rails.env])
    end
  end
end
