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

  describe '#new' do
    it 'redirects to the SAML Auth Request endpoint' do
      get :new
      expect(response).to redirect_to(%r(\Ahttp://localhost:8009/saml/auth\?SAMLRequest=))
    end
  end

  describe '#metadata' do
    it 'generates metadata' do
      get :metadata

      # Remove ID that can vary across requests
      expected_metadata = OneLogin::RubySaml::Metadata.new.generate(saml_config)
      metadata_pattern = Regexp.escape(expected_metadata).gsub(/ ID='[^']+'/, " ID='[\\w-]+'")
      expect(response.body).to match(Regexp.new(metadata_pattern))
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
    let(:saml_request) { double(:logout_request, {
        id: 42,
        name_id: name_id
      }) }
    let(:sam_response) { double(:logout_response)}
    let(:response_url) { 'http://localhost/logout_response' }


    before do
      allow(OneLogin::RubySaml::SloLogoutrequest).to receive(:new).and_return(saml_request)
      allow(OneLogin::RubySaml::SloLogoutresponse).to receive(:new).and_return(sam_response)
      allow(sam_response).to receive(:create).and_return(response_url)
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
