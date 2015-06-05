require 'rails_helper'

class Devise::SessionsController < ActionController::Base

end

require_relative '../../../app/controllers/devise/saml_sessions_controller'


describe Devise::SamlSessionsController, type: :controller do
  let(:saml_config) {
    OneLogin::RubySaml::Settings.new(YAML.load_file(File.expand_path('../../../support/sp/config/idp.yml', __FILE__))[Rails.env])
  }

  describe '#new' do
    it 'redirects to the SAML Auth Request endpoint' do
      get :new
      expect(response).to redirect_to(%r(\Ahttp://localhost:8009/saml/auth\?SAMLRequest=))
    end
  end

  describe '#metadata' do
    it "generates metadata" do
      get :metadata

      # Remove ID that can vary across requests
      expected_metadata = OneLogin::RubySaml::Metadata.new.generate(saml_config)
      metadata_pattern = Regexp.escape(expected_metadata).gsub(/ ID='[^']+'/, " ID='[\\w-]+'")
      expect(response.body).to match(Regexp.new(metadata_pattern))
    end
  end
end
