# frozen_string_literal: true

class PaymentServices::PaylamaP2p
  class Invoice < ::PaymentServices::PaylamaSbp::Invoice
    self.table_name = 'paylama_p2p_invoices'
  end
end
