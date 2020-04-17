require "rails"

module DeviseSamlAuthenticatable
  module Railtie
    class AttributeMapInitializer < Rails::Railtie
      initializer "devise_saml_authenticatable.saml_attribute_map" do
        Devise.saml_attribute_map ||= attribute_map_for_environment
      end

      def attribute_map_for_environment
        return nil unless File.exist?(attribute_map_path)

        attribute_map = YAML.load(File.read(attribute_map_path))
        if attribute_map.key?(Rails.env)
          attribute_map[Rails.env]
        else
          attribute_map
        end
      end

      def attribute_map_path
        Rails.root.join("config", "attribute-map.yml")
      end
    end
  end
end
