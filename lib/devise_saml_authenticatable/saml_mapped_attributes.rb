module SamlAuthenticatable
  class SamlMappedAttributes
    def initialize(attributes, attribute_map)
      @attributes = attributes
      @attribute_map = attribute_map
      @inverted_attribute_map = @attribute_map.invert
    end

    def saml_attribute_keys
      @attribute_map.keys
    end

    def resource_keys
      @attribute_map.values
    end

    def value_by_resource_key(key)
      value_by_saml_attribute_key(@inverted_attribute_map.fetch(String(key)))
    end

    def value_by_saml_attribute_key(key)
      @attributes[String(key)]
    end
  end
end
