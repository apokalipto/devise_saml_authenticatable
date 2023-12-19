module SamlAuthenticatable
  class SamlMappedAttributes
    def initialize(attributes, attribute_map)
      raise ArgumentError.new("Expected OneLogin::RubySaml::Attributes, got #{attributes.class.name}") unless attributes.kind_of?(OneLogin::RubySaml::Attributes)

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
      case config["attribute_type"]
      when "multi"
        @attributes.multi(String(key))
      when "single"
        @attributes.single(String(key))
      else
        warn("SAML attribute behaviour not specified. This relies on Ruby-SAML's OneLogin::RubySaml::Attributes.single_value_compatibility settings. Update attributes-map.yml or your custom resource hook to specify `attribute_type` and `resource_name`")

        @attributes[String(key)]
      end
    end
  end
end
