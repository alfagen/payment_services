# frozen_string_literal: true

class PayoutStatus
  attr_reader :payout_id, :server_response

  def initialize(payout:, server_response:)
    @payout = payout
    @payout_id = payout.id
    @server_response = server_response
  end

  def success?
    payout.complete_payout?
  end

  def failed?
    !success?
  end

  private

  attr_reader :payout
end
