# Tipper

Abandoned 2015 project with [tipper-ios](https://github.com/rromanchuk/tipper-ios), [tipper-web](https://github.com/rromanchuk/tipper-web), and [tipper](https://github.com/rromanchuk/tipper)

![TIPPER1](/tipper-1.png)
![TIPPER2](/tipper-2.png)
![TIPPER3](/tipper-3.png)
![TIPPER4](/tipper-4.png)
![TIPPER Web 1](/tipper-web1.png)
![TIPPER Web 2](/tipper-web2.png)
![TIPPER Web 3](/tipper-web3.png)
![TIPPER Web 4](/tipper-web4.png)

## Deploy

`bin/cap production deploy`

`bin/cap production deploy:restart`

## Deploying web
`ember deploy production`

## Process monitoring with leye (production only)
Logs and pids  are located in capistrano shared folder

#### Get info
`leye w`

#### Stop and quit all monitoring
`leye q -s`

#### Start monitoring
`leye load` from current release path


##### Route
```
Prefix Verb   URI Pattern                             Controller#Action
                                 GET    /auth/:provider/callback(.:format)      sessions#create
                  api_me_refresh GET    /api/me/refresh(.:format)               api/me#show {:subdomain=>"api", :format=>"json"}
                    api_register POST   /api/register(.:format)                 api/me#register {:subdomain=>"api", :format=>"json"}
                  api_disconnect DELETE /api/disconnect(.:format)               api/me#disconnect {:subdomain=>"api", :format=>"json"}
                     api_connect POST   /api/connect(.:format)                  api/me#connect {:subdomain=>"api", :format=>"json"}
                         api_sms POST   /api/sms(.:format)                      api/sms#download {:subdomain=>"api", :format=>"json"}
                     api_autotip POST   /api/autotip(.:format)                  api/me#autotip {:subdomain=>"api", :format=>"json"}
                          api_me POST   /api/me(.:format)                       api/me#create {:subdomain=>"api", :format=>"json"}
                                 GET    /api/me(.:format)                       api/me#show {:subdomain=>"api", :format=>"json"}
                         api_tip GET    /api/tips/:id(.:format)                 api/tips#show {:subdomain=>"api", :format=>"json"}
                 api_transaction GET    /api/transactions/:id(.:format)         api/transactions#show {:subdomain=>"api", :format=>"json"}
                     api_charges POST   /api/charges(.:format)                  api/charges#create {:subdomain=>"api", :format=>"json"}
               api_cognito_index POST   /api/cognito(.:format)                  api/cognito#create {:subdomain=>"api", :format=>"json"}
               api_address_index POST   /api/address(.:format)                  api/address#create {:subdomain=>"api", :format=>"json"}
                    api_user_tip GET    /api/users/:user_id/tips/:id(.:format)  api/tips#show {:subdomain=>"api", :format=>"json"}
                        api_user GET    /api/users/:id(.:format)                api/users#show {:subdomain=>"api", :format=>"json"}
                    api_settings GET    /api/settings(.:format)                 api/settings#index {:subdomain=>"api", :format=>"json"}
                     api_setting GET    /api/settings/:id(.:format)             api/settings#show {:subdomain=>"api", :format=>"json"}
                     admin_users GET    /users(.:format)                        admin/users#index
                      admin_user GET    /users/:id(.:format)                    admin/users#show
                      admin_tips GET    /tips(.:format)                         admin/tips#index
  withdrawals_admin_wallet_index GET    /wallet/withdrawals(.:format)           admin/wallet#withdrawals
 transactions_admin_wallet_index GET    /wallet/transactions(.:format)          admin/wallet#transactions
              admin_wallet_index GET    /wallet(.:format)                       admin/wallet#index
                                 POST   /wallet(.:format)                       admin/wallet#create
                new_admin_wallet GET    /wallet/new(.:format)                   admin/wallet#new
               edit_admin_wallet GET    /wallet/:id/edit(.:format)              admin/wallet#edit
                    admin_wallet GET    /wallet/:id(.:format)                   admin/wallet#show
                                 PATCH  /wallet/:id(.:format)                   admin/wallet#update
                                 PUT    /wallet/:id(.:format)                   admin/wallet#update
                                 DELETE /wallet/:id(.:format)                   admin/wallet#destroy
          admin_bitcoin_accounts GET    /bitcoin_accounts/index(.:format)       admin/bitcoin_accounts#index
   recent_admin_bitcoin_accounts GET    /bitcoin_accounts/recent(.:format)      admin/bitcoin_accounts#recent
addresses_admin_bitcoin_accounts GET    /bitcoin_accounts/addresses(.:format)   admin/bitcoin_accounts#addresses
  network_admin_bitcoin_accounts GET    /bitcoin_accounts/network(.:format)     admin/bitcoin_accounts#network
  balance_admin_bitcoin_accounts GET    /bitcoin_accounts/balance(.:format)     admin/bitcoin_accounts#balance
  reserve_admin_bitcoin_accounts GET    /bitcoin_accounts/reserve(.:format)     admin/bitcoin_accounts#reserve
   unspent_admin_bitcoin_account GET    /bitcoin_accounts/:id/unspent(.:format) admin/bitcoin_accounts#unspent
                                 GET    /bitcoin_accounts(.:format)             admin/bitcoin_accounts#index
                                 POST   /bitcoin_accounts(.:format)             admin/bitcoin_accounts#create
       new_admin_bitcoin_account GET    /bitcoin_accounts/new(.:format)         admin/bitcoin_accounts#new
      edit_admin_bitcoin_account GET    /bitcoin_accounts/:id/edit(.:format)    admin/bitcoin_accounts#edit
           admin_bitcoin_account GET    /bitcoin_accounts/:id(.:format)         admin/bitcoin_accounts#show
                                 PATCH  /bitcoin_accounts/:id(.:format)         admin/bitcoin_accounts#update
                                 PUT    /bitcoin_accounts/:id(.:format)         admin/bitcoin_accounts#update
                                 DELETE /bitcoin_accounts/:id(.:format)         admin/bitcoin_accounts#destroy
                      admin_root GET    /                                       admin/users#index
               letter_opener_web        /devel/emails                           LetterOpenerWeb::Engine
                             tip GET    /tip/:tip_id(.:format)                  index#index
                         privacy GET    /privacy(.:format)                      index#index
                           about GET    /about(.:format)                        index#index
                           login GET    /login(.:format)                        index#index
                          logout POST   /logout(.:format)                       index#index
                              me GET    /me(.:format)                           index#index
                            root GET    /                                       index#index

Routes for LetterOpenerWeb::Engine:
clear_letters DELETE /clear(.:format)                 letter_opener_web/letters#clear
delete_letter DELETE /:id(.:format)                   letter_opener_web/letters#destroy
      letters GET    /                                letter_opener_web/letters#index
       letter GET    /:id(/:style)(.:format)          letter_opener_web/letters#show
              GET    /:id/attachments/:file(.:format) letter_opener_web/letters#attachment

```
