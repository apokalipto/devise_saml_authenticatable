# -*- encoding: utf-8 -*-
require File.expand_path('../lib/devise_saml_authenticatable/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Josef Sauter']
  gem.email         = ['Josef.Sauter@gmail.com']
  gem.description   = 'SAML Authentication for devise'
  gem.summary       = 'SAML Authentication for devise'
  gem.homepage      = ''

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(/^bin\//).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(/^(test|spec|features)\//)
  gem.name          = 'devise_saml_authenticatable'
  gem.require_paths = ['lib']
  gem.version       = DeviseSamlAuthenticatable::VERSION

  gem.add_dependency('devise', '> 2.0.0')
  gem.add_dependency('ruby-saml', '>= 0.8.2')
end
