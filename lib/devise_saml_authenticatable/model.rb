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

      def update_with_password(params={})
        params.delete(:current_password)
        self.update_without_password(params)
      end	

      def update_without_password(params={})
        params.delete(:password)
        params.delete(:password_confirmation)

        result = update_attributes(params)
        result
      end

      module ClassMethods
        include DeviseSamlAuthenticatable::SamlConfig
        def authenticate_with_saml(saml_response)
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
          if (resource.nil? && !Devise.saml_create_user)
            logger.info("User(#{auth_value}) not found.  Not configured to create the user.")
            return nil 
          end

          if (resource.nil? && Devise.saml_create_user)
            logger.info("Creating user(#{auth_value}).")
            resource = new
            set_user_saml_attributes(resource,attributes)
            if (Devise.saml_use_subject)
              resource.send "#{key}=", auth_value
            end
            resource.save!
          end

          resource
        end

        def find_for_shibb_authentication(conditions)
          find_for_authentication(conditions)
        end

        def attribute_map
          @attribute_map ||= YAML.load(File.read("#{Rails.root}/config/attribute-map.yml"))
        end

        private

        def set_user_saml_attributes(user,attributes)
          attribute_map.each do |k,v|
            Rails.logger.info "Setting: #{v}, #{attributes[k]}"
            user.send "#{v}=", attributes[k]
          end
        end
      end
    end
  end
end
