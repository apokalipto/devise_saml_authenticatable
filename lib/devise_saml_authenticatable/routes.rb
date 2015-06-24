ActionDispatch::Routing::Mapper.class_eval do
  protected
  def devise_saml_authenticatable(mapping, controllers)
    resource :session, :only => [], :controller => controllers[:saml_sessions], :path => "" do
      get :new, :path => "saml/sign_in", :as => "new"
      post :create, :path=>"saml/auth"
      match :destroy, :path => mapping.path_names[:sign_out], :as => "destroy", :via => mapping.sign_out_via
      get :metadata, :path=>"saml/metadata"
      match :idp_sign_out, :path=>"saml/idp_sign_out", via: [:get, :post]
    end
  end
end
