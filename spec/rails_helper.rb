# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require 'spec_helper'

# Configure ActiveRecord for testing
ENV['RAILS_ENV'] ||= 'test'

# Load ActiveRecord and establish connection
require 'active_record'
require 'yaml'
require 'database_cleaner-active_record'
require 'active_support/time'
require 'active_record/fixtures'
require 'pathname'

# Configure time zone
Time.zone = 'UTC'

# Define Rails.root for fixtures
module Rails
  def self.root
    @root ||= Pathname.new(File.join(__dir__, '..'))
  end
end

db_config = YAML.load_file(File.join(__dir__, '..', 'config', 'database.yml'))
ActiveRecord::Base.establish_connection(db_config['test'])

# Create tables needed for tests
require_relative 'support/schema'
require_relative 'support/models'


# Configure RSpec for Rails/ActiveRecord
RSpec.configure do |config|
  # Clean up database before each test
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end