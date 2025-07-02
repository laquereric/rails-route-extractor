# frozen_string_literal: true

require "rails/railtie"

module RailsRouteExtractor
  class Railtie < Rails::Railtie
    railtie_name :rails_route_extractor

    rake_tasks do
      load "rails_route_extractor/tasks/extract.rake"
      load "rails_route_extractor/tasks/routes.rake"
      load "rails_route_extractor/tasks/cleanup.rake"
    end

    initializer "rails_route_extractor.configure" do |app|
      RailsRouteExtractor.configure do |config|
        config.rails_root = Rails.root.to_s
        config.extract_base_path = Rails.root.join("route_extracts").to_s
        
        # Add Rails-specific exclude patterns
        config.exclude_patterns += %w[
          db/migrate
          db/seeds.rb
          config/database.yml
          config/secrets.yml
          config/master.key
          config/credentials.yml.enc
        ]
      end
    end

    # Add generators if needed
    generators do
      require "rails_route_extractor/generators/install_generator"
    end
  end
end