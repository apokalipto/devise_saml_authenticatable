module DeviseSamlAuthenticatable

  class Logger    
    def self.send(message, logger = Rails.logger)
      if ::Devise.saml_logger
        logger.add 0, "  \e[36msaml:\e[0m #{message}"
      end
    end
  end

end
