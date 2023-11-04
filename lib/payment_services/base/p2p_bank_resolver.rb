# frozen_string_literal: true

class PaymentServices::Base
  class P2pBankResolver
    
    include Virtus.model

    attribute :invoicer

    def initialize(invoicer:)
      @invoicer = invoicer
    end

    def perform

    end

    private

    def invoicer_class_name
      @invoicer_class_name ||= invoicer.class.name
    end
  end
end
