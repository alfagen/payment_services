# frozen_string_literal: true

require 'logger'

module AutoLogger
  def logger
    @logger ||= Logger.new(STDOUT)
  end
end