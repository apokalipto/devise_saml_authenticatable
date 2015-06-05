class User < ActiveRecord::Base
  devise :saml_authenticateable

  attr_accessible :email
end