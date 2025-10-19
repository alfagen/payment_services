# frozen_string_literal: true

require 'active_record'

module PaymentServices
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
