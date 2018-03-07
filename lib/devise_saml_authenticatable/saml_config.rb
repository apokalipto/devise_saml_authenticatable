require 'ruby-saml'
module DeviseSamlAuthenticatable
  module SamlConfig
    def saml_config(idp_entity_id = nil)
      return file_based_config if file_based_config
      return adapter_based_config(idp_entity_id) if Devise.idp_settings_adapter
      return locator_based_config(idp_entity_id) if Devise.idp_record_locator
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

    def locator_based_config(idp_entity_id)
      record   = Devise.idp_record_locator.call(idp_entity_id)
      settings = record.settings
      return config_with_settings(settings)
    end

    def adapter_based_config(idp_entity_id)
      if Devise.idp_settings_adapter.is_a? Proc
        settings = Devise.idp_settings_adapter.call(idp_entity_id)
      else
        settings = Devise.idp_settings_adapter.settings(idp_entity_id)
      end

      return config_with_settings(settings)
    end

    def config_with_settings(settings)
      config = Marshal.load(Marshal.dump(Devise.saml_config))

      settings.each do |k, v|
        acc = "#{k.to_s}=".to_sym

        if config.respond_to? acc
          config.send(acc, v)
        end
      end
      {config: config, idp_provider_record: settings[:idp_provider_record]}
    end

    def get_idp_entity_id(params)
      if Devise.idp_entity_id_reader.is_a? Proc
        return Devise.idp_entity_id_reader.call(params)
      end
      Devise.idp_entity_id_reader.entity_id(params)
    end
  end
end
