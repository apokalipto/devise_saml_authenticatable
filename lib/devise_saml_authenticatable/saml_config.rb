require 'ruby-saml'
module DeviseSamlAuthenticatable
  module SamlConfig
    def saml_config(params)
      return file_based_config if file_based_config
      return adapter_based_config(params) if Devise.idp_settings_adapter

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

    def adapter_based_config(params)
      config = Marshal.load(Marshal.dump(Devise.saml_config))

      idp_settings_adapter.settings(params).each do |k,v|
        acc = "#{k.to_s}=".to_sym

        if config.respond_to? acc
          config.send(acc, v)
        end
      end
      config
    end

    def idp_settings_adapter
      if Devise.idp_settings_adapter.respond_to?(:settings)
        Devise.idp_settings_adapter
      else
        @idp_settings_adapter ||= Devise.idp_settings_adapter.constantize
      end
    end
  end
end
