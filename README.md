[![Build Status](https://travis-ci.org/apokalipto/devise_saml_authenticatable.svg?branch=master)](https://travis-ci.org/apokalipto/devise_saml_authenticatable)
# DeviseSamlAuthenticatable

Devise Saml Authenticatable is a Single-Sign-On authentication strategy for devise that relies on SAML.
It uses [ruby-saml][] to handle all SAML-related stuff.

## Installation

Add this line to your application's Gemfile:

    gem 'devise_saml_authenticatable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install devise_saml_authenticatable

## Usage

Follow the [normal devise installation process](https://github.com/plataformatec/devise/tree/master#getting-started). The controller filters and helpers are unchanged from normal devise usage.

### Configuring Models

In `app/models/<YOUR_MODEL>.rb` set the `:saml_authenticatable` strategy.

In the example the model is `user.rb`:

```ruby
  class User < ActiveRecord::Base
    ...
    devise :saml_authenticatable, :trackable
    ...
  end
```

### Configuring routes

In `config/routes.rb` add `devise_for` to set up helper methods and routes:

```ruby
devise_for :users
```

### Configuring the IdP

An extra step in SAML SSO setup is adding your application to your identity provider. The required setup is specific to each IdP, but we have some examples in [our wiki](https://github.com/apokalipto/devise_saml_authenticatable/wiki). You'll need to tell your IdP how to send requests and responses to your application.

- Creating a new session: `/users/saml/auth`
    - IdPs may call this the "consumer," "recipient," "destination," or even "single sign-on." This is where they send a SAML response for an authenticated user.
- Metadata: `/users/saml/metadata`
    - IdPs may call this the "audience."
- Single Logout: `/users/saml/idp_sign_out`
    - if desired, you can ask the IdP to send a Logout request to this endpoint to sign the user out of your application when they sign out of the IdP itself.
    
Your IdP should give you some information you need to configure in [ruby-saml](https://github.com/onelogin/ruby-saml), as in the next section:

- Issuer (`idp_entity_id`)
- SSO endpoint (`idp_sso_target_url`)
- SLO endpoint (`idp_slo_target_url`)
- Certificate fingerprint (`idp_cert_fingerprint`) and algorithm (`idp_cert_fingerprint_algorithm`)
    - Or the certificate itself (`idp_cert`)

### Configuring handling of IdP requests and responses

In `config/initializers/devise.rb`:

```ruby
  Devise.setup do |config|
    ...
    # ==> Configuration for :saml_authenticatable

    # Create user if the user does not exist. (Default is false)
    config.saml_create_user = true

    # Update the attributes of the user after a successful login. (Default is false)
    config.saml_update_user = true

    # Set the default user key. The user will be looked up by this key. Make
    # sure that the Authentication Response includes the attribute.
    config.saml_default_user_key = :email

    # Optional. This stores the session index defined by the IDP during login.  If provided it will be used as a salt
    # for the user's session to facilitate an IDP initiated logout request.
    config.saml_session_index_key = :session_index

    # You can set this value to use Subject or SAML assertation as info to which email will be compared.
    # If you don't set it then email will be extracted from SAML assertation attributes.
    config.saml_use_subject = true

    # You can support multiple IdPs by setting this value to a class that implements a #settings method which takes
    # an IdP entity id as an argument and returns a hash of idp settings for the corresponding IdP.
    config.idp_settings_adapter = nil

    # You provide you own method to find the idp_entity_id in a SAML message in the case of multiple IdPs
    # by setting this to a custom reader class, or use the default.
    # config.idp_entity_id_reader = DeviseSamlAuthenticatable::DefaultIdpEntityIdReader

    # You can set a handler object that takes the response for a failed SAML request and the strategy,
    # and implements a #handle method. This method can then redirect the user, return error messages, etc.
    # config.saml_failed_callback = nil

    # Configure with your SAML settings (see ruby-saml's README for more information: https://github.com/onelogin/ruby-saml).
    config.saml_configure do |settings|
      # assertion_consumer_service_url is required starting with ruby-saml 1.4.3: https://github.com/onelogin/ruby-saml#updating-from-142-to-143
      settings.assertion_consumer_service_url     = "http://localhost:3000/users/saml/auth"
      settings.assertion_consumer_service_binding = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
      settings.name_identifier_format             = "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
      settings.issuer                             = "http://localhost:3000/saml/metadata"
      settings.authn_context                      = ""
      settings.idp_slo_target_url                 = "http://localhost/simplesaml/www/saml2/idp/SingleLogoutService.php"
      settings.idp_sso_target_url                 = "http://localhost/simplesaml/www/saml2/idp/SSOService.php"
      settings.idp_cert_fingerprint               = "00:A1:2B:3C:44:55:6F:A7:88:CC:DD:EE:22:33:44:55:D6:77:8F:99"
      settings.idp_cert_fingerprint_algorithm     = "http://www.w3.org/2000/09/xmldsig#sha1"
    end
  end
```

In the config directory, create a YAML file (`attribute-map.yml`) that maps SAML attributes with your model's fields:

```yaml
  # attribute-map.yml

  "urn:mace:dir:attribute-def:uid": "user_name"
  "urn:mace:dir:attribute-def:email": "email"
  "urn:mace:dir:attribute-def:name": "last_name"
  "urn:mace:dir:attribute-def:givenName": "name"
```

The attribute mappings are very dependent on the way the IdP encodes the attributes.
In this example the attributes are given in URN style.
Other IdPs might provide them as OID's, or by other means.

You are now ready to test it against an IdP.

When the user visits `/users/saml/sign_in` they will be redirected to the login page of the IdP.

Upon successful login the user is redirected to the Devise `user_root_path`.

## Supporting Multiple IdPs

If you must support multiple Identity Providers you can implement an adapter class with a `#settings` method that takes an IdP entity id and returns a hash of settings for the corresponding IdP. The `config.idp_settings_adapter` then must be set to point to your adapter in `config/initializers/devise.rb`. The implementation of the adapter is up to you. A simple example may look like this:

```ruby
class IdPSettingsAdapter
  def self.settings(idp_entity_id)
    case idp_entity_id
    when "http://www.example_idp_entity_id.com"
      {
        assertion_consumer_service_url: "http://localhost:3000/users/saml/auth",
        assertion_consumer_service_binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST",
        name_identifier_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:transient",
        issuer: "http://localhost:3000/saml/metadata",
        idp_entity_id: "http://www.example_idp_entity_id.com",
        authn_context: "",
        idp_slo_target_url: "http://example_idp_slo_target_url.com",
        idp_sso_target_url: "http://example_idp_sso_target_url.com",
        idp_cert: "example_idp_cert"
      }
    when "http://www.another_idp_entity_id.biz"
      {
        assertion_consumer_service_url: "http://localhost:3000/users/saml/auth",
        assertion_consumer_service_binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST",
        name_identifier_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:transient",
        issuer: "http://localhost:3000/saml/metadata",
        idp_entity_id: "http://www.another_idp_entity_id.biz",
        authn_context: "",
        idp_slo_target_url: "http://another_idp_slo_target_url.com",
        idp_sso_target_url: "http://another_idp_sso_target_url.com",
        idp_cert: "another_idp_cert"
      }
    else
      {}
    end
  end
end
```
Settings specified in the adapter will override settings in `config/initializers/devise.rb`. This is useful for establishing common settings or defaults across all IdPs.

Detecting the entity ID passed to the `settings` method is done by `config.idp_entity_id_reader`.

By default this will find the `Issuer` in the SAML request.

You can support more use cases by writing your own and implementing the `.entity_id` method.

If you use encrypted assertions, your entity ID reader will need to understand how to decrypt the response from each of the possible IdPs.

## Identity Provider

If you don't have an identity provider and you would like to test the authentication against your app, there are some options:

1. Use [ruby-saml-idp](https://github.com/lawrencepit/ruby-saml-idp). You can add your own logic to your IdP, or you can also set it up as a dummy IdP that always sends a valid authentication response to your app.
2. Use an online service that can act as an IdP. OneLogin, Salesforce, Okta and some others provide you with this functionality.
3. Install your own IdP.

There are numerous IdPs that support SAML 2.0, there are propietary (like Microsoft ADFS 2.0 or Ping federate) and there are also open source solutions like Shibboleth and [SimpleSAMLphp].

[SimpleSAMLphp] was my choice for development since it is a production-ready SAML solution, that is also really easy to install, configure and use.

[SimpleSAMLphp]: http://simplesamlphp.org/

## Logout

Logout support is included by immediately terminating the local session and then redirecting to the IdP.

## Logout Request

Logout requests from the IDP are supported by the `idp_sign_out` endpoint.  Directing logout requests to `users/saml/idp_sign_out` will log out the respective user by invalidating their current sessions.

`saml_session_index_key` must be configured to support this feature.

## Signing and Encrypting Authentication Requests and Assertions

ruby-saml 1.0.0 supports signature and decrypt. The only requirement is to set the public certificate and the private key. For more information, see [the ruby-saml documentation](https://github.com/onelogin/ruby-saml#signing).

If you have multiple IdPs, the certificate and private key must be in the shared settings in `config/initializers/devise.rb`.

## Thanks

The continued maintenance of this gem could not have been possible without the hard work of [Adam Stegman](https://github.com/adamstegman) and [Mitch Lindsay](https://github.com/mitch-lindsay). Thank you guys for keeping this project alive.

Thanks to all other contributors that have also helped us make this software better.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Run the tests (`bundle exec rspec`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

[ruby-saml]: https://github.com/onelogin/ruby-saml
