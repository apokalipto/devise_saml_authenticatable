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

  describe '#new' do
    let(:saml_response) { File.read(File.join(File.dirname(__FILE__), '../../support', 'response_encrypted_nameid.xml.base64')) }

    subject(:do_get) {
      if Rails::VERSION::MAJOR > 4
        get :new, params: {"SAMLResponse" => saml_response}
      else
        get :new, "SAMLResponse" => saml_response
      end
    }

    context "when using the default saml config" do
      it "redirects to the IdP SSO target url" do
        do_get
        expect(response).to redirect_to(%r(\Ahttp://localhost:8009/saml/auth\?SAMLRequest=))
      end
    end

    context "with a specified idp" do
      before do
        Devise.idp_settings_adapter = idp_providers_adapter
      end

      it "redirects to the associated IdP SSO target url" do
        do_get
        expect(response).to redirect_to(%r(\Ahttp://idp_sso_url\?SAMLRequest=))
      end

      it "uses the DefaultIdpEntityIdReader" do
        expect(DeviseSamlAuthenticatable::DefaultIdpEntityIdReader).to receive(:entity_id)
        do_get
      end

      context "with a specified idp entity id reader" do
        class OurIdpEntityIdReader
          def self.entity_id(params)
            params[:entity_id]
          end
        end

        subject(:do_get) {
          if Rails::VERSION::MAJOR > 4
            get :new, params: {entity_id: "http://www.example.com"}
          else
            get :new, entity_id: "http://www.example.com"
          end
        }

        before do
          @default_reader = Devise.idp_entity_id_reader
          Devise.idp_entity_id_reader = OurIdpEntityIdReader # which will have some different behavior
        end

        after do
          Devise.idp_entity_id_reader = @default_reader
        end

        it "redirects to the associated IdP SSO target url" do
          do_get
          expect(response).to redirect_to(%r(\Ahttp://idp_sso_url\?SAMLRequest=))
        end
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
    let(:saml_response) { double(:slo_logoutresponse) }
    let(:response_url) { 'http://localhost/logout_response' }
    before do
      allow(OneLogin::RubySaml::SloLogoutresponse).to receive(:new).and_return(saml_response)
      allow(saml_response).to receive(:create).and_return(response_url)
    end

    it 'returns invalid request if SAMLRequest or SAMLResponse is not passed' do
      expect(User).not_to receive(:reset_session_key_for)
      post :idp_sign_out
      expect(response.status).to eq 500
    end

    context "when receiving a logout response from the IdP after redirecting an SP logout request" do
      subject(:do_post) {
        if Rails::VERSION::MAJOR > 4
          post :idp_sign_out, params: {SAMLResponse: "stubbed_response"}
        else
          post :idp_sign_out, SAMLResponse: "stubbed_response"
        end
      }

      it 'accepts a LogoutResponse and redirects sign_in' do
        do_post
        expect(response.status).to eq 302
        expect(response).to redirect_to '/users/saml/sign_in'
      end

      context 'when saml_sign_out_success_url is configured' do
        let(:test_url) { '/test/url' }
        before do
          Devise.saml_sign_out_success_url = test_url
        end

        it 'accepts a LogoutResponse and returns success' do
          do_post
          expect(response.status).to eq 302
          expect(response).to redirect_to test_url
        end
      end
    end

    context "when receiving an IdP logout request" do
      subject(:do_post) {
        if Rails::VERSION::MAJOR > 4
          post :idp_sign_out, params: {SAMLRequest: "stubbed_logout_request"}
        else
          post :idp_sign_out, SAMLRequest: "stubbed_logout_request"
        end
      }

      let(:saml_request) { double(:slo_logoutrequest, {
        id: 42,
        name_id: name_id,
        issuer: "http://www.example.com"
      }) }
      let(:name_id) { '12312312' }
      before do
        allow(OneLogin::RubySaml::SloLogoutrequest).to receive(:new).and_return(saml_request)
      end

      it 'direct the resource to reset the session key' do
        expect(User).to receive(:reset_session_key_for).with(name_id)
        do_post
        expect(response).to redirect_to response_url
      end

      context "with a specified idp" do
        let(:idp_entity_id) { "http://www.example.com" }
        before do
          Devise.idp_settings_adapter = idp_providers_adapter
        end

        it "accepts a LogoutResponse for the associated slo_target_url and redirects to sign_in" do
          do_post
          expect(response.status).to eq 302
          expect(idp_providers_adapter).to have_received(:settings).with(idp_entity_id)
          expect(response).to redirect_to "http://localhost/logout_response"
        end
      end

      context 'when saml_session_index_key is not configured' do
        before do
          Devise.saml_session_index_key = nil
        end

        it 'returns invalid request' do
          expect(User).not_to receive(:reset_session_key_for).with(name_id)
          do_post
          expect(response.status).to eq 500
        end
      end
    end
  end
end
