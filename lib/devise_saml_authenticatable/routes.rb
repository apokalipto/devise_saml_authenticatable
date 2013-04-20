ActionDispatch::Routing::Mapper.class_eval do
  protected
  def devise_saml_authenticatable(mapping, controllers)
    resource :session, :only => [], :controller => controllers[:saml_sessions], :path => "" do
      get :new, :path => "saml/sign_in", :as => "new"
      post :create, :path=>"saml/auth"
      match :destroy, :path => mapping.path_names[:sign_out], :as => "destroy"
      get :metadata, :path=>"saml/metadata"
    end
  end
end
