module DeviseSamlAuthenticatable
  class Logger
    def self.send(message, logger = Rails.logger)
      logger.add(0, "  \e[36msaml:\e[0m #{message}") if ::Devise.saml_logger
    end
  end
end
