# frozen_string_literal: true

module PaymentServices
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
