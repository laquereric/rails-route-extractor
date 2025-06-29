# frozen_string_literal: true

require_relative "route_extract/version"
require_relative "route_extract/configuration"
require_relative "route_extract/route_analyzer"
require_relative "route_extract/code_extractor"
require_relative "route_extract/dependency_tracker"
require_relative "route_extract/gem_analyzer"
require_relative "route_extract/file_analyzer"
require_relative "route_extract/extract_manager"
require_relative "route_extract/cli"

# Load Railtie if Rails is available
if defined?(Rails)
  require_relative "route_extract/railtie"
end

module RouteExtract
  class Error < StandardError; end

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

