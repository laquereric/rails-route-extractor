# frozen_string_literal: true

require_relative "rails_route_extractor/version"
require_relative "rails_route_extractor/configuration"
require_relative "rails_route_extractor/railtie"
require_relative "rails_route_extractor/route_analyzer"
require_relative "rails_route_extractor/gem_analyzer"


module RailsRouteExtractor
  # Define custom error classes
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class ExtractionError < Error; end
  class AnalysisError < Error; end

  class << self
    attr_accessor :configuration

    # Configure the gem
    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
      configuration
    end

    # Get current configuration
    def config
      self.configuration ||= Configuration.new
    end

    # Extract MVC code for a specific route
    def extract_route(route_pattern, options = {})
      manager = ExtractManager.new(config)
      manager.extract_route(route_pattern, options)
    end

    # Extract code for multiple routes
    def extract_routes(route_patterns, options = {})
      manager = ExtractManager.new(config)
      manager.extract_routes(route_patterns, options)
    end

    # List available routes
    def list_routes
      analyzer = RouteAnalyzer.new(config)
      analyzer.list_routes
    end

    # Get route information
    def route_info(route_pattern)
      analyzer = RouteAnalyzer.new(config)
      analyzer.route_info(route_pattern)
    end

    # Clean up extract directory
    def cleanup_extracts(options = {})
      manager = ExtractManager.new(config)
      manager.cleanup_extracts(options)
    end
  end
end

