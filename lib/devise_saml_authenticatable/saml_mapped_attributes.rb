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

      # When an attribute is "multi", return the entire array
      # When the attribute is "single", return the first value
      saml_value = nil

      # Find the first non-nil value
      attribute_map_for_key.each_pair do |saml_key, config|
        saml_value = value_by_saml_attribute_key(saml_key, config)

        break unless saml_value.nil?
      end

      saml_value
    end

    def value_by_saml_attribute_key(key, config)
      # If this is a multiple value attribute, temporarily force multiple values, then switch back to prior behaviour.
      # This feels completely wrong, but it's a class method.
      # Alternative - raise exception if this is on but you are asking for a single attribute?
      if config["attribute_type"] == "multi"
        single_value = OneLogin::RubySaml::Attributes.single_value_compatibility
        OneLogin::RubySaml::Attributes.single_value_compatibility = false
        values = @attributes[String(key)]
        OneLogin::RubySaml::Attributes.single_value_compatibility = single_value
        return values
      end

      @attributes[String(key)]
    end
  end
end
