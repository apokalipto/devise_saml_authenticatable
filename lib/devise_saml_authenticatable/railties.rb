require "rails"

module DeviseSamlAuthenticatable
  module Railtie
    class AttributeMapInitializer < Rails::Railtie
      initializer "devise_saml_authenticatable.saml_attribute_map" do |app|
        Devise.saml_attribute_map ||= attribute_map_for_environment
      end

      def attribute_map_for_environment
        attribute_map = YAML.safe_load(File.read("#{Rails.root}/config/attribute-map.yml"))
        if attribute_map.key?(Rails.env)
          attribute_map[Rails.env]
        else
          attribute_map
        end
      end
    end
  end
end
