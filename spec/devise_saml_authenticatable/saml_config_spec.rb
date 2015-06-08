require 'spec_helper'

describe DeviseSamlAuthenticatable::SamlConfig do
  subject(:saml_config) { controller.get_saml_config }
  let(:controller) { Class.new { include DeviseSamlAuthenticatable::SamlConfig }.new }

  it "is the global devise SAML config" do
    Devise.saml_configure do |config|
      config.assertion_consumer_logout_service_binding = 'test'
    end
    expect(saml_config).to be(Devise.saml_config)
    expect(saml_config.assertion_consumer_logout_service_binding).to eq('test')
  end

  context "when config/idp.yml exists" do
    before do
      allow(Rails).to receive(:env).and_return("environment")
      allow(File).to receive(:exists?).with("/config/idp.yml").and_return(true)
      allow(File).to receive(:read).with("/config/idp.yml").and_return(<<-IDP)
---
environment:
  assertion_consumer_logout_service_binding: assertion_consumer_logout_service_binding
  assertion_consumer_logout_service_url: assertion_consumer_logout_service_url
  assertion_consumer_service_binding: assertion_consumer_service_binding
  assertion_consumer_service_url: assertion_consumer_service_url
  attributes_index: attributes_index
  authn_context: authn_context
  authn_context_comparison: authn_context_comparison
  authn_context_decl_ref: authn_context_decl_ref
  certificate: certificate
  compress_request: compress_request
  compress_response: compress_response
  double_quote_xml_attribute_values: double_quote_xml_attribute_values
  force_authn: force_authn
  idp_cert: idp_cert
  idp_cert_fingerprint: idp_cert_fingerprint
  idp_cert_fingerprint_algorithm: idp_cert_fingerprint_algorithm
  idp_entity_id: idp_entity_id
  idp_slo_target_url: idp_slo_target_url
  idp_sso_target_url: idp_sso_target_url
  issuer: issuer
  name_identifier_format: name_identifier_format
  name_identifier_value: name_identifier_value
  passive: passive
  private_key: private_key
  protocol_binding: protocol_binding
  security: security
  sessionindex: sessionindex
  sp_name_qualifier: sp_name_qualifier
      IDP
    end

    it "stores the configured IdP settings" do
      expect(saml_config.assertion_consumer_logout_service_binding).to eq('assertion_consumer_logout_service_binding')
      expect(saml_config.assertion_consumer_logout_service_url).to eq('assertion_consumer_logout_service_url')
      expect(saml_config.assertion_consumer_service_binding).to eq('assertion_consumer_service_binding')
      expect(saml_config.assertion_consumer_service_url).to eq('assertion_consumer_service_url')
      expect(saml_config.attributes_index).to eq('attributes_index')
      expect(saml_config.authn_context).to eq('authn_context')
      expect(saml_config.authn_context_comparison).to eq('authn_context_comparison')
      expect(saml_config.authn_context_decl_ref).to eq('authn_context_decl_ref')
      expect(saml_config.certificate).to eq('certificate')
      expect(saml_config.compress_request).to eq('compress_request')
      expect(saml_config.compress_response).to eq('compress_response')
      expect(saml_config.double_quote_xml_attribute_values).to eq('double_quote_xml_attribute_values')
      expect(saml_config.force_authn).to eq('force_authn')
      expect(saml_config.idp_cert).to eq('idp_cert')
      expect(saml_config.idp_cert_fingerprint).to eq('idp_cert_fingerprint')
      expect(saml_config.idp_cert_fingerprint_algorithm).to eq('idp_cert_fingerprint_algorithm')
      expect(saml_config.idp_entity_id).to eq('idp_entity_id')
      expect(saml_config.idp_slo_target_url).to eq('idp_slo_target_url')
      expect(saml_config.idp_sso_target_url).to eq('idp_sso_target_url')
      expect(saml_config.issuer).to eq('issuer')
      expect(saml_config.name_identifier_format).to eq('name_identifier_format')
      expect(saml_config.name_identifier_value).to eq('name_identifier_value')
      expect(saml_config.passive).to eq('passive')
      expect(saml_config.private_key).to eq('private_key')
      expect(saml_config.protocol_binding).to eq('protocol_binding')
      expect(saml_config.security).to eq('security')
      expect(saml_config.sessionindex).to eq('sessionindex')
      expect(saml_config.sp_name_qualifier).to eq('sp_name_qualifier')
    end
  end
end
