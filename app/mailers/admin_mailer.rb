class AdminMailer < ApplicationMailer
  
  def wallet_notify(tx)
    @tx = tx
    mail(to: ['rromanchuk@gmail.com', 'marcus.siegel@gmail.com', "ivan.kataitsev@gmail.com"], subject: "Wallet notify #{tx["category"]}: #{tx["amount"]}")
  end

end
