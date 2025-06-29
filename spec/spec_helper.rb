# frozen_string_literal: true

require "route_extract"
require "simplecov"

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/vendor/"
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Clean up test extracts after each test
  config.after(:each) do
    test_extract_path = File.join(Dir.pwd, "test_route_extracts")
    FileUtils.rm_rf(test_extract_path) if File.exist?(test_extract_path)
  end
end

