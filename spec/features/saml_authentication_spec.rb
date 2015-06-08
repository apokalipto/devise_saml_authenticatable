require 'spec_helper'
require 'capybara/rspec'
require 'capybara/webkit'
Capybara.default_driver = :webkit

describe "SAML Authentication", type: :feature do
  before(:all) do
    create_app('idp')
    create_app('sp')
    @idp_pid = start_app('idp', 8009)
    @sp_pid  = start_app('sp',  8020)
  end
  after(:all) do
    stop_app(@idp_pid)
    stop_app(@sp_pid)
  end

  it "authenticates a user on a SP via an IdP" do
    visit 'http://localhost:8020/'
    expect(current_url).to match(%r(\Ahttp://localhost:8009/saml/auth\?SAMLRequest=))
    fill_in "Email", with: "you@example.com"
    fill_in "Password", with: "asdf"
    click_on "Sign in"
    expect(page).to have_content(/home/i)
    expect(current_url).to eq("http://localhost:8020/")
  end
end
