require 'spec_helper'

class Devise::SessionsController < ActionController::Base

end

require_relative '../../../app/controllers/devise/saml_sessions_controller'


describe Devise::SamlSessionsController, type: :controller do

  before do
    @saml_config = OneLogin::RubySaml::Settings.new({})
  end

  describe '#new' do
    it 'redirects to the SAML Auth Request endpoint' do
      get :new
      expect(response).to redirect_to(OneLogin::RubySaml::Authrequest.new.create(@saml_config))
    end
  end

end