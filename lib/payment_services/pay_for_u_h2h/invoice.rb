# frozen_string_literal: true


module PaymentServices
  class PayForUH2h
    class Invoice < ::PaymentServices::PayForU::Invoice
      self.table_name = 'pay_for_u_h2h_invoices'
    end
  end
end
