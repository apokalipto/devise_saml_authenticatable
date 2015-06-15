require 'rails_helper'

class Devise::SessionsController < ActionController::Base
  attr_accessor :warden

  # The important parts from devise
  def destroy
    sign_out
    redirect_to after_sign_out_path_for(:user)
  end

  def navigational_formats
    Devise.navigational_formats.select { |format| Mime::EXTENSION_LOOKUP[format.to_s] }
  end

  def resource_name
    :user
  end
end

require_relative '../../../app/controllers/devise/saml_sessions_controller'

describe Devise::SamlSessionsController, type: :controller do
  let(:saml_config) { Devise.saml_config }

  let(:warden) { double(:warden) }
  let(:user_session) { {} }
  before do
    allow(warden).to receive(:session).with(:user).and_return(user_session)
    controller.warden = warden
  end

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

    context "when a logout assertion consumer service url is set" do
      before do
        @original_saml_config = Devise.saml_config
        Devise.saml_config = Devise.saml_config.dup
        Devise.saml_config.assertion_consumer_logout_service_url = "http://localhost:8020/users/signed_out"
      end
      after do
        Devise.saml_config = @original_saml_config
      end

      it 'does not sign out, but sets logout transaction id' do
      expect(controller).not_to receive(:sign_out).and_call_original
      delete :destroy
      expect(response).to redirect_to(%r(\Ahttp://localhost:8009/saml/logout\?SAMLRequest=))
      expect(controller.warden.session(:user)[:logout_request_id]).not_to be_nil
      end
    end
  end
end
