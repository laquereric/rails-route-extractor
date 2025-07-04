# frozen_string_literal: true

require_relative "lib/rails_route_extractor/version"

Gem::Specification.new do |spec|
  spec.name = "rails_route_extractor"
  spec.version = RailsRouteExtractor::VERSION
  spec.authors = ["RailsRouteExtractor Team"]
  spec.email = ["laquereric@gmail.com"]

  spec.summary = "Extract Model, View, Controller code for specific Rails routes"
  spec.description = "A Ruby gem that builds on rails_route_tester and codeql_db to provide rake tasks for extracting MVC code required for particular routes, including referenced gem source files."
  spec.homepage = "https://github.com/laquereric/rails_route_extractor"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/laquereric/rails_route_extractor"
  spec.metadata["changelog_uri"] = "https://github.com/laquereric/rails_route_extractor/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z 2>/dev/null`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "activesupport", ">= 6.0"

  # Development dependencies
  #spec.add_development_dependency "rails_route_tester", ">= 0.1.0"
  # spec.add_development_dependency "codeql_db", ">= 0.1.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "cucumber", "~> 7.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "simplecov", "~> 0.21"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end

