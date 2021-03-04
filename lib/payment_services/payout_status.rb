# frozen_string_literal: true

class PayoutStatus
  attr_reader :server_response

  def initialize(payout:, server_response:)
    @payout = payout
    @server_response = server_response
  end

  def success?
    payout.complete_payout?
  end

  private

  attr_reader :payout
end
