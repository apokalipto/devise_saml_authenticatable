require 'spec_helper'

describe Devise::Strategies::SamlAuthenticatable do
  subject(:strategy) { described_class.new(env, :user) }
  let(:env) { {} }

  let(:response) { double(:response, :settings= => nil, attributes: attributes, is_valid?: true) }
  let(:attributes) { double(:attributes) }
  before do
    allow(OneLogin::RubySaml::Response).to receive(:new).and_return(response)
  end

  let(:saml_config) { OneLogin::RubySaml::Settings.new }
  before do
    allow(strategy).to receive(:get_saml_config).and_return(saml_config)
  end

  let(:mapping) { double(:mapping, to: user_class) }
  let(:user_class) { double(:user_class, authenticate_with_saml: user) }
  let(:user) { double(:user) }
  before do
    allow(strategy).to receive(:mapping).and_return(mapping)
  end

  let(:params) { {} }
  before do
    allow(strategy).to receive(:params).and_return(params)
  end

  context "with a SAMLResponse parameter" do
    let(:params) { {SAMLResponse: ""} }

    it "is valid" do
      expect(strategy).to be_valid
    end

    it "authenticates with the response attributes" do
      expect(OneLogin::RubySaml::Response).to receive(:new).with(params[:SAMLResponse])
      expect(response).to receive(:settings=).with(saml_config)
      expect(user_class).to receive(:authenticate_with_saml).with(attributes)

      expect(strategy).to receive(:success!).with(user)
      strategy.authenticate!
    end

    context "and the SAML response is not valid" do
      before do
        allow(response).to receive(:is_valid?).and_return(false)
      end

      it "fails to authenticate" do
        expect(strategy).to receive(:fail!).with(:invalid)
        strategy.authenticate!
      end
    end
  end

  it "is not valid without a SAMLResponse parameter" do
    expect(strategy).not_to be_valid
  end

  it "is permanent" do
    expect(strategy).to be_store
  end
end
