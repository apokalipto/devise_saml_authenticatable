require 'rails_helper'

class Devise::SessionsController < ActionController::Base
  # The important parts from devise
  def resource_class
    User
  end

  def destroy
    sign_out
    redirect_to after_sign_out_path_for(:user)
  end

  def require_no_authentication
  end
end

require_relative '../../../app/controllers/devise/saml_sessions_controller'

describe Devise::SamlSessionsController, type: :controller do
  let(:saml_config) { Devise.saml_config }
  let(:idp_providers_adapter) { spy("Stub IDPSettings Adaptor") }

  before do
    @original_saml_config = Devise.saml_config
    @original_sign_out_success_url = Devise.saml_sign_out_success_url
    @original_saml_session_index_key = Devise.saml_session_index_key

    allow(idp_providers_adapter).to receive(:settings).and_return({
      assertion_consumer_service_url: "acs_url",
      assertion_consumer_service_binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST",
      name_identifier_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
      issuer: "sp_issuer",
      idp_entity_id: "http://www.example.com",
      authn_context: "",
      idp_slo_target_url: "http://idp_slo_url",
      idp_sso_target_url: "http://idp_sso_url",
      idp_cert: "idp_cert"
    })
  end

  after do
    Devise.saml_config = @original_saml_config
    Devise.saml_sign_out_success_url = @original_sign_out_success_url
    Devise.saml_session_index_key = @original_saml_session_index_key
    Devise.idp_settings_adapter = nil
  end

  describe '#new' do
    let(:saml_response) { File.read(File.join(File.dirname(__FILE__), '../../support', 'response_encrypted_nameid.xml.base64')) }

    context "when using the default saml config" do
      it "redirects to the IdP SSO target url" do
        get :new, "SAMLResponse" => saml_response
        expect(response).to redirect_to(%r(\Ahttp://localhost:8009/saml/auth\?SAMLRequest=))
      end
    end

    context "with a specified idp" do
      before do
        Devise.idp_settings_adapter = idp_providers_adapter
      end

      it "redirects to the associated IdP SSO target url" do
        get :new, "SAMLResponse" => saml_response
        expect(response).to redirect_to(%r(\Ahttp://idp_sso_url\?SAMLRequest=))
      end
    end
  end

  describe '#metadata' do
    context "with the default configuration" do
      it 'generates metadata' do
        get :metadata

        # Remove ID that can vary across requests
        expected_metadata = OneLogin::RubySaml::Metadata.new.generate(saml_config)
        metadata_pattern = Regexp.escape(expected_metadata).gsub(/ ID='[^']+'/, " ID='[\\w-]+'")
        expect(response.body).to match(Regexp.new(metadata_pattern))
      end
    end

    context "with a specified IDP" do
      let(:saml_config) { controller.saml_config("anything") }

      before do
        Devise.idp_settings_adapter = idp_providers_adapter
        Devise.saml_configure do |settings|
          settings.assertion_consumer_service_url = "http://localhost:3000/users/saml/auth"
          settings.assertion_consumer_service_binding = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
          settings.name_identifier_format = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
          settings.issuer = "http://localhost:3000"
        end
      end

      it "generates the same service metadata" do
        get :metadata

        # Remove ID that can vary across requests
        expected_metadata = OneLogin::RubySaml::Metadata.new.generate(saml_config)
        metadata_pattern = Regexp.escape(expected_metadata).gsub(/ ID='[^']+'/, " ID='[\\w-]+'")
        expect(response.body).to match(Regexp.new(metadata_pattern))
      end
    end
  end

  describe '#destroy' do
    it 'signs out and redirects to the IdP' do
      expect(controller).to receive(:sign_out)
      delete :destroy
      expect(response).to redirect_to(%r(\Ahttp://localhost:8009/saml/logout\?SAMLRequest=))
    end
  end

  describe '#idp_sign_out' do
    let(:name_id) { '12312312' }
    let(:saml_request) { double(:slo_logoutrequest, {
      id: 42,
      name_id: name_id,
      issuer: "http://www.example.com"
    }) }
    let(:saml_response) { double(:slo_logoutresponse) }
    let(:response_url) { 'http://localhost/logout_response' }

    before do
      allow(OneLogin::RubySaml::SloLogoutrequest).to receive(:new).and_return(saml_request)
      allow(OneLogin::RubySaml::SloLogoutresponse).to receive(:new).and_return(saml_response)
      allow(saml_response).to receive(:create).and_return(response_url)
    end

    it 'returns invalid request if SAMLRequest is not passed' do
      expect(User).not_to receive(:reset_session_key_for).with(name_id)
      post :idp_sign_out
      expect(response.status).to eq 500
    end

    it 'accepts a LogoutResponse and redirects sign_in' do
      post :idp_sign_out, SAMLResponse: 'stubbed_response'
      expect(response.status).to eq 302
      expect(response).to redirect_to '/users/saml/sign_in'
    end

    context "with a specified idp" do
      let(:idp_entity_id) { "http://www.example.com" }
      before do
        Devise.idp_settings_adapter = idp_providers_adapter
      end

      it "accepts a LogoutResponse for the associated slo_target_url and redirects to sign_in" do
        post :idp_sign_out, SAMLRequest: "stubbed_logout_request"
        expect(response.status).to eq 302
        expect(idp_providers_adapter).to have_received(:settings).with(idp_entity_id)
        expect(response).to redirect_to "http://localhost/logout_response"
      end
    end

    context 'when saml_sign_out_success_url is configured' do
      let(:test_url) { '/test/url' }
      before do
        Devise.saml_sign_out_success_url = test_url
      end

      it 'accepts a LogoutResponse and returns success' do
        post :idp_sign_out, SAMLResponse: 'stubbed_response'
        expect(response.status).to eq 302
        expect(response).to redirect_to test_url
      end
    end

    context 'when saml_session_index_key is not configured' do
      before do
        Devise.saml_session_index_key = nil
      end

      it 'returns invalid request' do
        expect(User).not_to receive(:reset_session_key_for).with(name_id)
        post :idp_sign_out, SAMLRequest: 'stubbed_request'
        expect(response.status).to eq 500
      end
    end

    it 'direct the resource to reset the session key' do
      expect(User).to receive(:reset_session_key_for).with(name_id)
      post :idp_sign_out, SAMLRequest: 'stubbed_request'
      expect(response).to redirect_to response_url
    end
  end
end
