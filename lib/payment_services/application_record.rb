# frozen_string_literal: true

require 'active_record'
require 'money-rails'
require 'money-rails/active_record/monetizable'
require 'money-rails/active_model/validator'

module PaymentServices
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    include MoneyRails::ActiveRecord::Monetizable
  end
end
