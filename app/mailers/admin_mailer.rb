class AdminMailer < ApplicationMailer
  
  def wallet_notify(tx)
    @tx = tx
    mail(to: ['***REMOVED***', 'marcus.siegel@gmail.com'], subject: "WALLET EVENT: Amount in/out: #{tx["amount"]}, Fees: #{tx["fee"]}")
  end

end
