# frozen_string_literal: true

require 'rails/generators'

module RailsRouteExtractor
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Install RouteExtract in your Rails application"
      
      source_root File.expand_path('templates', __dir__)
      
      def create_initializer
        template 'initializer.rb', 'config/initializers/route_extract.rb'
      end
      
      def create_extract_directory
        empty_directory 'route_extracts'
        create_file 'route_extracts/.gitkeep'
      end
      
      def add_to_gitignore
        gitignore_path = Rails.root.join('.gitignore')
        
        if File.exist?(gitignore_path)
          gitignore_content = File.read(gitignore_path)
          
          unless gitignore_content.include?('route_extracts/')
            append_to_file '.gitignore' do
              "\n# RouteExtract generated files\nroute_extracts/\n"
            end
          end
        end
      end
      
      def show_readme
        say "\n" + "="*60
        say "RouteExtract has been installed!"
        say "="*60
        say "\nNext steps:"
        say "1. Review the configuration in config/initializers/route_extract.rb"
        say "2. Run 'rake route_extract:help' to see available tasks"
        say "3. Try extracting a route: 'rake route_extract:extract[users#index]'"
        say "\nFor more information, visit: https://github.com/laquereric/route_extract"
        say "="*60 + "\n"
      end
    end
  end
end

