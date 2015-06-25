# The latest version of the ruby-saml SloLogoutrequest class does not include accessors to pull the
# session index from the LogoutRequest data.  This access was added in the following commit but no released yet.
# https://github.com/onelogin/ruby-saml/commit/7424e891ce853a903e4d9e0a953eed151185e4e1
# Remove this shim when a gem version including this commit is released.
class SamlSloLogoutrequest < OneLogin::RubySaml::SloLogoutrequest
  def session_indexes
    s_indexes = []
    nodes = REXML::XPath.match(
      document,
      "/p:LogoutRequest/p:SessionIndex",
      { "p" => PROTOCOL }
    )

    nodes.each do |node|
      s_indexes << node.text
    end

    s_indexes
  end
end