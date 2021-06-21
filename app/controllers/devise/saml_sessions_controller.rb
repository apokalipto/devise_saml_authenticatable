require "ruby-saml"

class Devise::SamlSessionsController < Devise::SessionsController
  include DeviseSamlAuthenticatable::SamlConfig
  unloadable if Rails::VERSION::MAJOR < 4
  if Rails::VERSION::MAJOR < 5
    skip_before_filter :verify_authenticity_token
    prepend_before_filter :verify_signed_out_user, :store_info_for_sp_initiated_logout, only: :destroy
  else
    skip_before_action :verify_authenticity_token, raise: false
    prepend_before_action :verify_signed_out_user, :store_info_for_sp_initiated_logout, only: :destroy
  end

  def new
    request = OneLogin::RubySaml::Authrequest.new
    auth_params = { RelayState: relay_state } if relay_state
    action = request.create(saml_config(params), auth_params || {})
    redirect_to action
  end

  def metadata
    meta = OneLogin::RubySaml::Metadata.new
    render :xml => meta.generate(saml_config(params))
  end

  def idp_sign_out
    if params[:SAMLRequest] && Devise.saml_session_index_key
      saml_config = saml_config(params)
      logout_request = OneLogin::RubySaml::SloLogoutrequest.new(params[:SAMLRequest], settings: saml_config)
      resource_class.reset_session_key_for(logout_request.name_id)

      redirect_to generate_idp_logout_response(saml_config, logout_request.id)
    elsif params[:SAMLResponse]
      # Currently Devise handles the session invalidation when the request is made.
      # To support a true SP initiated logout response, the request ID would have to be tracked and session invalidated
      # based on that.
      if Devise.saml_sign_out_success_url
        redirect_to Devise.saml_sign_out_success_url
      else
        redirect_to action: :new
      end
    else
      head 500
    end
  end

  protected

  def relay_state
    @relay_state ||= if Devise.saml_relay_state.present?
      Devise.saml_relay_state.call(request)
    end
  end

  # For non transient name ID, save info to identify user for logout purpose
  # before that user's session got destroyed. These info are used in the
  # `after_sign_out_path_for` method below.
  def store_info_for_sp_initiated_logout
    return if Devise.saml_config.name_identifier_format == "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
    @name_identifier_value_for_sp_initiated_logout = Devise.saml_name_identifier_retriever.call(current_user)
    @sessionindex_for_sp_initiated_logout = current_user.public_send(Devise.saml_session_index_key) if Devise.saml_session_index_key
  end

  # Override devise to send user to IdP logout for SLO
  def after_sign_out_path_for(_)
    request = OneLogin::RubySaml::Logoutrequest.new
    saml_settings = saml_config(params).dup

    # Add attributes to saml_settings which will later be used to create the SP
    # initiated logout request
    unless Devise.saml_config.name_identifier_format == 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
      saml_settings.name_identifier_value = @name_identifier_value_for_sp_initiated_logout
      saml_settings.sessionindex = @sessionindex_for_sp_initiated_logout
    end

    request.create(saml_settings)
  end

  # Overried devise: if user is signed out, not create the SP initiated logout request,
  # redirect to saml_sign_out_success_url,
  # or devise's after_sign_out_path_for
  def verify_signed_out_user
    if all_signed_out?
      set_flash_message! :notice, :already_signed_out

      redirect_to Devise.saml_sign_out_success_url.presence ||
                  Devise::SessionsController.new.after_sign_out_path_for(resource_name)
    end
  end

  def generate_idp_logout_response(saml_config, logout_request_id)

    params = {}
    if relay_state
      params[:RelayState] = relay_state
    end

    OneLogin::RubySaml::SloLogoutresponse.new.create(saml_config, logout_request_id, nil, params)
  end
end
