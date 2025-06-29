# frozen_string_literal: true

require "rails/railtie"

module RouteExtract
  class Railtie < Rails::Railtie
    railtie_name :route_extract

    rake_tasks do
      load "route_extract/tasks/extract.rake"
      load "route_extract/tasks/routes.rake"
      load "route_extract/tasks/cleanup.rake"
    end

    initializer "route_extract.configure" do |app|
      RouteExtract.configure do |config|
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
      require "route_extract/generators/install_generator"
    end
  end
end

