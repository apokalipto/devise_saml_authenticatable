require "spec_helper"

describe DeviseSamlAuthenticatable::DefaultIdpEntityIdReader do
  describe ".entity_id" do
    context "when there is a SAMLRequest in the params" do
      let(:params) { {SAMLRequest: "logout request"} }
      let(:slo_logout_request) { double('slo_logout_request', issuer: 'meow')}
      it "uses an OneLogin::RubySaml::SloLogoutrequest to get the idp_entity_id" do
        expect(OneLogin::RubySaml::SloLogoutrequest).to receive(:new).and_return(slo_logout_request)
        described_class.entity_id(params)
      end
    end

    context "when there is a SAMLResponse in the params" do
      let(:params) { {SAMLResponse: "auth response"} }
      let(:response) { double('response', issuers: ['meow'] )}
      it "uses an OneLogin::RubySaml::Response to get the idp_entity_id" do
        expect(OneLogin::RubySaml::Response).to receive(:new).and_return(response)
        described_class.entity_id(params)
      end
    end
  end
end
