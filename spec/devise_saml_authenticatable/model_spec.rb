require 'spec_helper'

describe Devise::Models::SamlAuthenticatable do
  class Model
    include Devise::Models::SamlAuthenticatable
    attr_accessor :email, :saved
    def save!
      self.saved = true
    end

    # Fake out ActiveRecord and Devise API to satisfy verifiable mocks
    class << self
      def where(*args); end
      def logger; end
    end
  end

  before do
    logger = double(:logger).as_null_object
    allow(Model).to receive(:logger).and_return(logger)
    allow(Rails).to receive(:logger).and_return(logger)
  end

  before do
    allow(Devise).to receive(:saml_default_user_key).and_return(:email)
  end

  before do
    allow(Rails).to receive(:root).and_return("/railsroot")
    allow(File).to receive(:read).with("/railsroot/config/attribute-map.yml").and_return(<<-ATTRIBUTEMAP)
---
"saml-email-format": email
      ATTRIBUTEMAP
  end

  it "looks up the user by the configured default user key" do
    user = double(:user)
    expect(Model).to receive(:where).with(email: 'user@example.com').and_return([user])
    expect(Model.authenticate_with_saml('saml-email-format' => 'user@example.com')).to eq(user)
  end

  it "returns nil if it cannot find a user" do
    expect(Model).to receive(:where).with(email: 'user@example.com').and_return([])
    expect(Model.authenticate_with_saml('saml-email-format' => 'user@example.com')).to be_nil
  end

  context "when configured to create a user and the user is not found" do
    before do
      allow(Devise).to receive(:saml_create_user).and_return(true)
    end

    it "creates and returns a new user with the given attributes" do
      expect(Model).to receive(:where).with(email: 'user@example.com').and_return([])
      model = Model.authenticate_with_saml('saml-email-format' => 'user@example.com')
      expect(model.email).to eq('user@example.com')
      expect(model.saved).to be(true)
    end
  end

  context "when configured with a case-insensitive key" do
    before do
      allow(Devise).to receive(:case_insensitive_keys).and_return([:email])
    end

    it "looks up the user with a downcased value" do
      user = double(:user)
      expect(Model).to receive(:where).with(email: 'user@example.com').and_return([user])
      expect(Model.authenticate_with_saml('saml-email-format' => 'UsEr@ExAmPlE.cOm')).to eq(user)
    end
  end
end
