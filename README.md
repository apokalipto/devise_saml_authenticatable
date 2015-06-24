[![Build Status](https://travis-ci.org/apokalipto/devise_saml_authenticatable.svg?branch=master)](https://travis-ci.org/apokalipto/devise_saml_authenticatable)
# DeviseSamlAuthenticatable

Devise Saml Authenticatable is a Single-Sign-On authentication strategy for devise that relies on SAML.
It uses [ruby-saml][] to handle all SAML related stuff.

## Installation

Add this line to your application's Gemfile:

    gem 'devise_saml_authenticatable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install devise_saml_authenticatable

## Usage

In `app/models/<YOUR_MODEL>.rb` set the `:saml_authenticatable` strategy.
In the example the model is `user.rb`:

```ruby
  class User < ActiveRecord::Base
    ...
    devise :saml_authenticatable, :trackable
    ...
  end
```

In config/initializers/devise.rb

```ruby
  Devise.setup do |config|
    ...
    # ==> Configuration for :saml_authenticatable
    
    # Create user if the user does not exist. (Default is false)
    config.saml_create_user = true
    
    # Set the default user key. The user will be looked up by this key. Make
    # sure that the Authentication Response includes the attribute.
    config.saml_default_user_key = :email

    # Optional. This stores the session index defined by the IDP during login.  If provided it will be used as a salt
    # for the user's session to facilitate an IDP initiated logout request.
    config.saml_session_index_key = :session_index

    # You can set this value to use Subject or SAML assertation as info to which email will be compared
    # If you don't set it then email will be extracted from SAML assertation attributes
    config.saml_use_subject = true

    # Configure with your SAML settings (see [ruby-saml][] for more information).
    config.saml_configure do |settings|
      settings.assertion_consumer_service_url     = "http://localhost:3000/users/saml/auth"
      settings.assertion_consumer_service_binding = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
      settings.name_identifier_format             = "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
      settings.issuer                             = "http://localhost:3000"
      settings.authn_context                      = ""
      settings.idp_slo_target_url                 = "http://localhost/simplesaml/www/saml2/idp/SingleLogoutService.php"
      settings.idp_sso_target_url                 = "http://localhost/simplesaml/www/saml2/idp/SSOService.php"
      settings.idp_cert                           = <<-CERT.chomp
-----BEGIN CERTIFICATE-----
1111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111
1111111111111_______IDP_CERTIFICATE________111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111
111111111111111111
-----END CERTIFICATE-----
      CERT
    end
  end
```

In config directory create a YAML file (`attribute-map.yml`) that maps SAML attributes with your model's fields:

```yaml
  # attribute-map.yml
  
  "urn:mace:dir:attribute-def:uid": "user_name"
  "urn:mace:dir:attribute-def:email": "email"
  "urn:mace:dir:attribute-def:name": "last_name"
  "urn:mace:dir:attribute-def:givenName": "name"
```

The attribute mappings are very dependent on the way the IdP encodes the attributes.
In this example the attributes are given in URN style.
Other IdPs might provide them as OID's or other means.

You are now ready to test it against an IdP.
When the user goes to `/users/saml/sign_in` he will be redirected to the login page of the IdP.
Upon successful login the user is redirected to devise `user_root_path`.

## Identity Provider

If you don't have an identity provider an you would like to test the authentication against your app there are some options:

1. Use [ruby-saml-idp](https://github.com/lawrencepit/ruby-saml-idp). You can add your own logic to your IdP, or you can also set it as a dummy IdP that always sends a valid authentication response to your app.
2. Use an online service that can act as an IdP. Onelogin, Salesforce and some others provide you with this functionality
3. Install your own IdP.

There are numerous IdPs that support SAML 2.0, there are propietary (like Microsoft ADFS 2.0 or Ping federate) and there are also open source solutions like Shibboleth and simplesamlphp.

[SimpleSAMLphp](http://simplesamlphp.org/) was my choice for development since it is a production-ready SAML solution, that is also really easy to install, configure and use.

## Logout

Logout support is included by immediately terminating the local session and then redirecting to the IdP.

## Logout Request

Logout requests from the IDP are supported by the `idp_sign_out` end point.  Directing logout requests to `users/saml/idp_sign_out` will logout the respective user by invalidating their current sessions.
`saml_session_index_key` must be configured to support this feature.

## Limitations

1. The Authentication Requests (from your app to the IdP) are not signed and encrypted

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
