require 'devise_saml_authenticatable/strategy'

module Devise
  module Models
    module SamlAuthenticatable
      extend ActiveSupport::Concern

      # Need to determine why these need to be included
      included do
        attr_reader :password, :current_password
        attr_accessor :password_confirmation
      end

      def after_saml_authentication(session_index)
        if Devise.saml_session_index_key && self.respond_to?(Devise.saml_session_index_key)
          self.update_attribute(Devise.saml_session_index_key, session_index)
        end
      end

      def authenticatable_salt
        if Devise.saml_session_index_key &&
           self.respond_to?(Devise.saml_session_index_key) &&
           self.send(Devise.saml_session_index_key).present?
          self.send(Devise.saml_session_index_key)
        else
          super
        end
      end

      module ClassMethods
        def authenticate_with_saml(saml_response, relay_state)
          key = Devise.saml_default_user_key
          attributes = saml_response.attributes
          if (Devise.saml_use_subject)
            auth_value = saml_response.name_id
          else
            inv_attr = attribute_map.invert
            auth_value = attributes[inv_attr[key.to_s]]
            auth_value.try(:downcase!) if Devise.case_insensitive_keys.include?(key)
          end
          resource = where(key => auth_value).first

          if resource.nil?
            if Devise.saml_create_user
              logger.info("Creating user(#{auth_value}).")
              resource = new
            else
              logger.info("User(#{auth_value}) not found.  Not configured to create the user.")
              return nil
            end
          end

          if Devise.saml_update_user || (resource.new_record? && Devise.saml_create_user)
            set_user_saml_attributes(resource, attributes)
            if (Devise.saml_use_subject)
              resource.send "#{key}=", auth_value
            end
            resource.save!
          end

          resource
        end

        def reset_session_key_for(name_id)
          resource = find_by(Devise.saml_default_user_key => name_id)
          resource.update_attribute(Devise.saml_session_index_key, nil) unless resource.nil?
        end

        def find_for_shibb_authentication(conditions)
          find_for_authentication(conditions)
        end

        def attribute_map
          @attribute_map ||= Devise.attribute_map || attribute_map_for_environment
        end

        private

        def set_user_saml_attributes(user, attributes)
          if defined?(Devise.set_user_saml_attributes_custom_function)
            Devise.set_user_saml_attributes_custom_function.call(user, attributes)
          else
            attribute_map.each do |k, v|
              Rails.logger.info "Setting: #{v}, #{attributes[k]}"
              user.send "#{v}=", attributes[k]
            end
          end
        end

        def attribute_map_for_environment
          attribute_map = YAML.load(File.read("#{Rails.root}/config/attribute-map.yml"))
          if attribute_map.has_key?(Rails.env)
            attribute_map[Rails.env]
          else
            attribute_map
          end
        end
      end
    end
  end
end
