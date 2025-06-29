# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

# Load gem tasks
begin
  require "route_extract"
  load "lib/route_extract/tasks/extract.rake"
  load "lib/route_extract/tasks/routes.rake"
  load "lib/route_extract/tasks/cleanup.rake"
rescue LoadError
  # Gem not yet built, skip loading tasks
end

