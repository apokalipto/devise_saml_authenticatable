module SamlAuthenticatable
  class SamlMappedAttributes
    def initialize(attributes, attribute_map)
      @attributes = attributes
      @attribute_map = attribute_map
    end

    def saml_attribute_keys
      @attribute_map.keys
    end

    def resource_keys
      @attribute_map.values.map { |h| h["resource_key"] }
    end

    def value_by_resource_key(key)
      str_key = String(key)

      # Find all of the SAML attributes that map to the resource key
      attribute_map_for_key = @attribute_map.select { |_, config| String(config["resource_key"]) == str_key }

      saml_value = nil
      attribute_map_for_key.each_pair do |saml_key, config|
        saml_value = value_by_saml_attribute_key(saml_key, config)

        break unless saml_value.nil?
      end

      saml_value
    end

    def value_by_saml_attribute_key(key, config)
      case config["attribute_type"]
      when "single"
        return @attributes[String(key)]&.first
      when "multi"
        return @attributes[String(key)]
      end
    end
  end
end
