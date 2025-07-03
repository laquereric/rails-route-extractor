# frozen_string_literal: true

require "rails_route_extractor"
require "simplecov"
require "pry"

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/vendor/"
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Configure test environment
  config.before(:suite) do
    # Create test extract directory
    test_extract_path = File.join(Dir.pwd, "test_route_extracts")
    FileUtils.mkdir_p(test_extract_path) unless Dir.exist?(test_extract_path)
  end

  config.after(:suite) do
    # Clean up test extracts
    test_extract_path = File.join(Dir.pwd, "test_route_extracts")
    FileUtils.rm_rf(test_extract_path) if Dir.exist?(test_extract_path)
  end
end

