require 'rails_helper'

class Devise::SessionsController < ActionController::Base
  # The important parts from devise
  def destroy
    sign_out
    redirect_to after_sign_out_path_for(:user)
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
end
