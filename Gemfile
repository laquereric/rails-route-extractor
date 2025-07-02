# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in route_extract.gemspec
gemspec

gem "rake", "~> 13.0"
gem "rspec", "~> 3.0"
gem "rubocop", "~> 1.21"

# Development dependencies
group :development do
  gem "rails_route_tester", git: "https://github.com/laquereric/rails_route_tester"
  # gem "ruby_codeql_db", git: "https://github.com/laquereric/codeql_db"
  gem "yard", "~> 0.9"
  gem "simplecov", "~> 0.21"
  gem "cucumber", "~> 7.0"
end

group :test do
  gem "rails", "~> 7.0"
  gem "sqlite3", "~> 1.4"
  gem "factory_bot", "~> 6.0"
end

