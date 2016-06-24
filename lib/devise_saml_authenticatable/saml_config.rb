require 'ruby-saml'
module DeviseSamlAuthenticatable
  module SamlConfig
    def saml_config(idp_entity_id = nil)
      return file_based_config if file_based_config
      return adapter_based_config(idp_entity_id) if Devise.idp_settings_adapter

      Devise.saml_config
    end

    private

    def file_based_config
      return @file_based_config if @file_based_config
      idp_config_path = "#{Rails.root}/config/idp.yml"

      if File.exists?(idp_config_path)
        @file_based_config ||= OneLogin::RubySaml::Settings.new(YAML.load(File.read(idp_config_path))[Rails.env])
      end
    end

    def adapter_based_config(idp_entity_id)
      config = Marshal.load(Marshal.dump(Devise.saml_config))

      Devise.idp_settings_adapter.settings(idp_entity_id).each do |k,v|
        acc = "#{k.to_s}=".to_sym

        if config.respond_to? acc
          config.send(acc, v)
        end
      end
      config
    end

    def get_idp_entity_id(params)
      Devise.idp_entity_id_reader.entity_id(params)
    end
  end
end
