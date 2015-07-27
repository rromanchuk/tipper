Rails.application.routes.draw do
  namespace :api, path: '/', defaults: { format: 'json' } do
    get 'settings' => 'settings#index'
    resource :me,                  only: [:create, :show, :index], controller: 'me'
    resources :charges, only: [:create]
    resources :cognito, only: [:create]
  end


  namespace :admin, path: '/', constraints: { subdomain: /wwwadmin.*/ } do
    resources :users,  only: [:index, :show]
    resources :tips,  only: [:index]
    resources :wallet do
      collection do 
        get 'withdrawals'
        get 'transactions'
      end
    end

    resources :bitcoin_accounts do 
      collection do 
        get 'index'
        get 'recent'
        get 'addresses'
        get 'network'
        get 'balance'
        get 'reserve'
      end

      member do 
        get 'unspent'
      end
    end
    root to: 'users#index'
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/devel/emails"
  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'home#index'

end
