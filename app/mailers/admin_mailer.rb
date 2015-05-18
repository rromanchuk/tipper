class AdminMailer < ApplicationMailer
  
  def wallet_notify(tx)
    @tx = tx
    mail(to: ['rromanchuk@gmail.com', 'marcus.siegel@gmail.com'], subject: "#{tx["category"]}: #{tx["amount"]}, Fees: #{tx["fee"]}")
  end

end
