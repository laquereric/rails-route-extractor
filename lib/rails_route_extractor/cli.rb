# frozen_string_literal: true

require "thor"
require_relative '../rails_route_extractor'

module RailsRouteExtractor
  class CLI < Thor
    include Thor::Actions

    class_option :verbose, type: :boolean, default: false, desc: "Enable verbose output"
    class_option :rails_root, type: :string, desc: "Rails application root directory"

    desc "extract ROUTE_PATTERN", "Extract MVC code for a specific route"
    option :mode, type: :string, default: "mvc", desc: "Extraction mode: mvc, m, v, c, mv, mc, vc"
    option :output, type: :string, desc: "Output directory (default: route_extracts)"
    option :include_gems, type: :boolean, default: true, desc: "Include gem source files"
    option :include_tests, type: :boolean, default: false, desc: "Include test files"
    option :compress, type: :boolean, default: false, desc: "Compress extract into archive"
    def extract(route_pattern)
      configure_from_options
      
      say "Extracting route: #{route_pattern}", :green
      
      begin
        result = RailsRouteExtractor.extract_route(route_pattern, extract_options)
        
        if result[:success]
          say "✓ Successfully extracted to: #{result[:extract_path]}", :green
          say "  Files extracted: #{result[:files_count]}", :blue
          say "  Total size: #{result[:total_size]}", :blue
        else
          say "✗ Extraction failed: #{result[:error]}", :red
          exit 1
        end
      rescue => e
        say "✗ Error: #{e.message}", :red
        say e.backtrace.join("\n") if options[:verbose]
        exit 1
      end
    end

    desc "extract_multiple PATTERN1,PATTERN2,...", "Extract MVC code for multiple routes"
    option :mode, type: :string, default: "mvc", desc: "Extraction mode: mvc, m, v, c, mv, mc, vc"
    option :output, type: :string, desc: "Output directory (default: route_extracts)"
    option :include_gems, type: :boolean, default: true, desc: "Include gem source files"
    option :include_tests, type: :boolean, default: false, desc: "Include test files"
    option :compress, type: :boolean, default: false, desc: "Compress extracts into archives"
    def extract_multiple(patterns)
      configure_from_options
      
      route_patterns = patterns.split(",").map(&:strip)
      say "Extracting #{route_patterns.length} routes", :green
      
      begin
        result = RailsRouteExtractor.extract_routes(route_patterns, extract_options)
        
        if result[:success]
          say "✓ Successfully extracted #{result[:successful_count]} routes", :green
          say "✗ Failed to extract #{result[:failed_count]} routes", :red if result[:failed_count] > 0
          say "  Total files extracted: #{result[:total_files]}", :blue
          say "  Total size: #{result[:total_size]}", :blue
        else
          say "✗ Extraction failed: #{result[:error]}", :red
          exit 1
        end
      rescue => e
        say "✗ Error: #{e.message}", :red
        say e.backtrace.join("\n") if options[:verbose]
        exit 1
      end
    end

    desc "list", "List all available routes"
    option :filter, type: :string, desc: "Filter routes by pattern"
    option :format, type: :string, default: "table", desc: "Output format: table, json, csv"
    def list
      configure_from_options
      
      begin
        routes = RailsRouteExtractor.list_routes
        
        if options[:filter]
          routes = routes.select { |route| route[:pattern].match?(Regexp.new(options[:filter], Regexp::IGNORECASE)) }
        end
        
        case options[:format]
        when "json"
          puts JSON.pretty_generate(routes)
        when "csv"
          puts routes.map { |r| "#{r[:pattern]},#{r[:controller]},#{r[:action]},#{r[:method]}" }.join("\n")
        else
          print_routes_table(routes)
        end
      rescue => e
        say "✗ Error: #{e.message}", :red
        say e.backtrace.join("\n") if options[:verbose]
        exit 1
      end
    end

    desc "info ROUTE_PATTERN", "Show detailed information about a route"
    def info(route_pattern)
      configure_from_options
      
      begin
        info = RailsRouteExtractor.route_info(route_pattern)
        
        if info
          say "Route Information:", :green
          say "  Pattern: #{info[:pattern]}", :blue
          say "  Controller: #{info[:controller]}", :blue
          say "  Action: #{info[:action]}", :blue
          say "  HTTP Method: #{info[:method]}", :blue
          say "  Helper: #{info[:helper]}", :blue if info[:helper]
          
          if info[:files]
            say "\nAssociated Files:", :green
            info[:files].each do |file_type, files|
              say "  #{file_type.to_s.capitalize}:", :yellow
              files.each { |file| say "    #{file}", :white }
            end
          end
        else
          say "✗ Route not found: #{route_pattern}", :red
          exit 1
        end
      rescue => e
        say "✗ Error: #{e.message}", :red
        say e.backtrace.join("\n") if options[:verbose]
        exit 1
      end
    end

    desc "cleanup", "Clean up extract directories"
    option :older_than, type: :string, desc: "Remove extracts older than specified time (e.g., '7d', '1w', '1m')"
    option :force, type: :boolean, default: false, desc: "Force cleanup without confirmation"
    def cleanup
      configure_from_options
      
      begin
        result = RailsRouteExtractor.cleanup_extracts(cleanup_options)
        
        if result[:success]
          say "✓ Cleaned up #{result[:removed_count]} extract directories", :green
          say "  Space freed: #{result[:space_freed]}", :blue
        else
          say "✗ Cleanup failed: #{result[:error]}", :red
          exit 1
        end
      rescue => e
        say "✗ Error: #{e.message}", :red
        say e.backtrace.join("\n") if options[:verbose]
        exit 1
      end
    end

    desc "version", "Show version information"
    def version
      say "RailsRouteExtractor version #{RailsRouteExtractor::VERSION}", :green
    end

    private

    def configure_from_options
      RailsRouteExtractor.configure do |config|
        config.verbose = options[:verbose]
        config.rails_root = options[:rails_root] if options[:rails_root]
      end
    end

    def extract_options
      opts = {
        mode: options[:mode],
        include_gems: options[:include_gems],
        include_tests: options[:include_tests],
        compress: options[:compress]
      }
      opts[:output] = options[:output] if options[:output]
      opts
    end

    def cleanup_options
      opts = {
        force: options[:force]
      }
      opts[:older_than] = options[:older_than] if options[:older_than]
      opts
    end

    def print_routes_table(routes)
      return say("No routes found", :yellow) if routes.empty?
      
      say "Available Routes:", :green
      say "-" * 80
      say sprintf("%-30s %-20s %-15s %-10s", "Pattern", "Controller", "Action", "Method")
      say "-" * 80
      
      routes.each do |route|
        say sprintf("%-30s %-20s %-15s %-10s", 
                   route[:pattern], 
                   route[:controller], 
                   route[:action], 
                   route[:method])
      end
    end
  end
end

