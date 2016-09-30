require 'spec_helper'

describe Devise::Models::SamlAuthenticatable do
  class Model
    include Devise::Models::SamlAuthenticatable
    attr_accessor :email, :name, :saved
    def initialize(params = {})
      @email = params[:email]
      @name = params[:name]
      @new_record = params.fetch(:new_record, true)
    end

    def new_record?
      @new_record
    end

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
    allow(Devise).to receive(:saml_create_user).and_return(false)
    allow(Devise).to receive(:saml_use_subject).and_return(false)
  end

  before do
    allow(Rails).to receive(:root).and_return("/railsroot")
    allow(File).to receive(:read).with("/railsroot/config/attribute-map.yml").and_return(<<-ATTRIBUTEMAP)
---
"saml-email-format": email
"saml-name-format":  name
      ATTRIBUTEMAP
  end

  let(:response) { double(:response, attributes: attributes, name_id: name_id) }
  let(:attributes) {
    OneLogin::RubySaml::Attributes.new(
      'saml-email-format' => ['user@example.com'],
      'saml-name-format'  => ['A User'],
    )
  }
  let(:name_id) { nil }

  it "looks up the user by the configured default user key" do
    user = Model.new(new_record: false)
    expect(Model).to receive(:where).with(email: 'user@example.com').and_return([user])
    expect(Model.authenticate_with_saml(response, nil)).to eq(user)
  end

  it "returns nil if it cannot find a user" do
    expect(Model).to receive(:where).with(email: 'user@example.com').and_return([])
    expect(Model.authenticate_with_saml(response, nil)).to be_nil
  end

  context "when configured to use the subject" do
    let(:attributes) { OneLogin::RubySaml::Attributes.new('saml-name-format' => ['A User']) }
    let(:name_id) { 'user@example.com' }

    before do
      allow(Devise).to receive(:saml_use_subject).and_return(true)
    end

    it "looks up the user by the configured default user key" do
      user = Model.new(new_record: false)
      expect(Model).to receive(:where).with(email: 'user@example.com').and_return([user])
      expect(Model.authenticate_with_saml(response, nil)).to eq(user)
    end

    it "returns nil if it cannot find a user" do
      expect(Model).to receive(:where).with(email: 'user@example.com').and_return([])
      expect(Model.authenticate_with_saml(response, nil)).to be_nil
    end

    context "when configured to create a user and the user is not found" do
      before do
        allow(Devise).to receive(:saml_create_user).and_return(true)
      end

      it "creates and returns a new user with the name identifier and given attributes" do
        expect(Model).to receive(:where).with(email: 'user@example.com').and_return([])
        model = Model.authenticate_with_saml(response, nil)
        expect(model.email).to eq('user@example.com')
        expect(model.name).to  eq('A User')
        expect(model.saved).to be(true)
      end
    end

    context "when configured to update a user and the user is found" do
      before do
        allow(Devise).to receive(:saml_update_user).and_return(true)
      end

      it "creates and returns a new user with the name identifier and given attributes" do
        user = Model.new(email: "old_mail@mail.com", name: "old name", new_record: false)
        expect(Model).to receive(:where).with(email: 'user@example.com').and_return([user])
        model = Model.authenticate_with_saml(response, nil)
        expect(model.email).to eq('user@example.com')
        expect(model.name).to  eq('A User')
        expect(model.saved).to be(true)
      end
    end
  end

  context "when configured to create an user and the user is not found" do
    before do
      allow(Devise).to receive(:saml_create_user).and_return(true)
    end

    it "creates and returns a new user with the given attributes" do
      expect(Model).to receive(:where).with(email: 'user@example.com').and_return([])
      model = Model.authenticate_with_saml(response, nil)
      expect(model.email).to eq('user@example.com')
      expect(model.name).to  eq('A User')
      expect(model.saved).to be(true)
    end
  end

  context "when configured to update an user" do
    before do
      allow(Devise).to receive(:saml_update_user).and_return(true)
    end

    it "returns nil if the user is not found" do
      expect(Model).to receive(:where).with(email: 'user@example.com').and_return([])
      expect(Model.authenticate_with_saml(response, nil)).to be_nil
    end

    it "updates the attributes if the user is found" do
      user = Model.new(email: "old_mail@mail.com", name: "old name", new_record: false)
      expect(Model).to receive(:where).with(email: 'user@example.com').and_return([user])
      model = Model.authenticate_with_saml(response, nil)
      expect(model.email).to eq('user@example.com')
      expect(model.name).to  eq('A User')
      expect(model.saved).to be(true)
    end
  end


  context "when configured with a case-insensitive key" do
    before do
      allow(Devise).to receive(:case_insensitive_keys).and_return([:email])
    end

    it "looks up the user with a downcased value" do
      user = Model.new(new_record: false)
      expect(Model).to receive(:where).with(email: 'user@example.com').and_return([user])
      expect(Model.authenticate_with_saml(response, nil)).to eq(user)
    end
  end
end
