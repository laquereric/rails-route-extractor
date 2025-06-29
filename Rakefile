# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

# Load custom rake tasks
require "rails_route_extractor"
load "lib/rails_route_extractor/tasks/extract.rake"
load "lib/rails_route_extractor/tasks/routes.rake"
load "lib/rails_route_extractor/tasks/cleanup.rake"

# Custom tasks for development
task :test_gem do
  puts "Testing RailsRouteExtractor gem..."
  system("ruby bin/test")
end

task :validate_structure do
  puts "Validating gem structure..."
  system("python validate_gem.py")
end

