class AdminMailer < ApplicationMailer
  
  def wallet_notify(tx)
    @tx = tx
    mail(to: ['rromanchuk@gmail.com', 'marcus.siegel@gmail.com'], subject: "WALLET EVENT: #{tx["amount"]}, Fees: #{tx["fee"]}")
  end

end
