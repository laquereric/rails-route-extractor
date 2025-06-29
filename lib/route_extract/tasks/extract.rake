# frozen_string_literal: true

namespace :route_extract do
  desc "Extract MVC code for a specific route"
  task :extract, [:route_pattern, :mode] => :environment do |t, args|
    require 'route_extract'
    
    route_pattern = args[:route_pattern]
    mode = args[:mode] || ENV['MODE'] || 'mvc'
    
    unless route_pattern
      puts "Usage: rake route_extract:extract[route_pattern,mode]"
      puts "Example: rake route_extract:extract[users#index,mvc]"
      puts "Modes: m, v, c, mv, mc, vc, mvc"
      exit 1
    end
    
    # Configure from environment variables
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
      config.include_gems = ENV['INCLUDE_GEMS'] != 'false'
      config.include_tests = ENV['INCLUDE_TESTS'] == 'true'
      config.compress_extracts = ENV['COMPRESS'] == 'true'
    end
    
    options = {
      mode: mode,
      include_gems: RouteExtract.config.include_gems,
      include_tests: RouteExtract.config.include_tests,
      compress: RouteExtract.config.compress_extracts
    }
    
    puts "Extracting route: #{route_pattern} (mode: #{mode})"
    
    result = RouteExtract.extract_route(route_pattern, options)
    
    if result[:success]
      puts "✓ Successfully extracted to: #{result[:extract_path]}"
      puts "  Files extracted: #{result[:files_count]}"
      puts "  Total size: #{result[:total_size]}"
    else
      puts "✗ Extraction failed: #{result[:error]}"
      exit 1
    end
  end

  desc "Extract MVC code for multiple routes"
  task :extract_multiple, [:route_patterns] => :environment do |t, args|
    require 'route_extract'
    
    route_patterns_str = args[:route_patterns]
    
    unless route_patterns_str
      puts "Usage: rake route_extract:extract_multiple[route1,route2,route3]"
      puts "Example: rake route_extract:extract_multiple[users#index,users#show,posts#index]"
      exit 1
    end
    
    route_patterns = route_patterns_str.split(',').map(&:strip)
    
    # Configure from environment variables
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
      config.include_gems = ENV['INCLUDE_GEMS'] != 'false'
      config.include_tests = ENV['INCLUDE_TESTS'] == 'true'
      config.compress_extracts = ENV['COMPRESS'] == 'true'
    end
    
    mode = ENV['MODE'] || 'mvc'
    options = {
      mode: mode,
      include_gems: RouteExtract.config.include_gems,
      include_tests: RouteExtract.config.include_tests,
      compress: RouteExtract.config.compress_extracts
    }
    
    puts "Extracting #{route_patterns.length} routes (mode: #{mode})"
    
    result = RouteExtract.extract_routes(route_patterns, options)
    
    if result[:success]
      puts "✓ Successfully extracted #{result[:successful_count]} routes"
      puts "  Total files extracted: #{result[:total_files]}"
      puts "  Total size: #{result[:total_size]}"
    else
      puts "✗ Extraction completed with errors"
      puts "  Successful: #{result[:successful_count]}"
      puts "  Failed: #{result[:failed_count]}"
      
      if RouteExtract.config.verbose
        result[:results].each do |res|
          if res[:success]
            puts "  ✓ #{res[:route_pattern]}"
          else
            puts "  ✗ #{res[:route_pattern]}: #{res[:error]}"
          end
        end
      end
    end
  end

  desc "Extract MVC code for all routes matching a pattern"
  task :extract_pattern, [:pattern] => :environment do |t, args|
    require 'route_extract'
    
    pattern = args[:pattern]
    
    unless pattern
      puts "Usage: rake route_extract:extract_pattern[pattern]"
      puts "Example: rake route_extract:extract_pattern[users]"
      exit 1
    end
    
    # Configure from environment variables
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
      config.include_gems = ENV['INCLUDE_GEMS'] != 'false'
      config.include_tests = ENV['INCLUDE_TESTS'] == 'true'
      config.compress_extracts = ENV['COMPRESS'] == 'true'
    end
    
    mode = ENV['MODE'] || 'mvc'
    options = {
      mode: mode,
      include_gems: RouteExtract.config.include_gems,
      include_tests: RouteExtract.config.include_tests,
      compress: RouteExtract.config.compress_extracts
    }
    
    puts "Extracting routes matching pattern: #{pattern} (mode: #{mode})"
    
    manager = RouteExtract::ExtractManager.new(RouteExtract.config)
    result = manager.extract_routes_by_pattern(pattern, options)
    
    if result[:success]
      puts "✓ Successfully extracted #{result[:successful_count]} routes"
      puts "  Total files extracted: #{result[:total_files]}"
      puts "  Total size: #{result[:total_size]}"
    else
      puts "✗ Extraction failed: #{result[:error]}"
      exit 1
    end
  end

  desc "Extract MVC code for all routes in a controller"
  task :extract_controller, [:controller_name] => :environment do |t, args|
    require 'route_extract'
    
    controller_name = args[:controller_name]
    
    unless controller_name
      puts "Usage: rake route_extract:extract_controller[controller_name]"
      puts "Example: rake route_extract:extract_controller[users]"
      exit 1
    end
    
    # Configure from environment variables
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
      config.include_gems = ENV['INCLUDE_GEMS'] != 'false'
      config.include_tests = ENV['INCLUDE_TESTS'] == 'true'
      config.compress_extracts = ENV['COMPRESS'] == 'true'
    end
    
    mode = ENV['MODE'] || 'mvc'
    options = {
      mode: mode,
      include_gems: RouteExtract.config.include_gems,
      include_tests: RouteExtract.config.include_tests,
      compress: RouteExtract.config.compress_extracts
    }
    
    puts "Extracting all routes for controller: #{controller_name} (mode: #{mode})"
    
    manager = RouteExtract::ExtractManager.new(RouteExtract.config)
    result = manager.extract_controller_routes(controller_name, options)
    
    if result[:success]
      puts "✓ Successfully extracted #{result[:successful_count]} routes"
      puts "  Total files extracted: #{result[:total_files]}"
      puts "  Total size: #{result[:total_size]}"
    else
      puts "✗ Extraction failed: #{result[:error]}"
      exit 1
    end
  end

  desc "Show extraction statistics"
  task :stats => :environment do
    require 'route_extract'
    
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end
    
    manager = RouteExtract::ExtractManager.new(RouteExtract.config)
    stats = manager.extraction_statistics
    
    puts "Extraction Statistics:"
    puts "  Total extracts: #{stats[:extracts_count]}"
    puts "  Total size: #{stats[:total_size]}"
    puts "  Oldest extract: #{stats[:oldest]&.strftime('%Y-%m-%d %H:%M:%S') || 'N/A'}"
    puts "  Newest extract: #{stats[:newest]&.strftime('%Y-%m-%d %H:%M:%S') || 'N/A'}"
    
    if RouteExtract.config.verbose && stats[:extract_paths].any?
      puts "\nExtract directories:"
      stats[:extract_paths].each do |path|
        puts "  #{File.basename(path)}"
      end
    end
  end

  desc "List all existing extracts"
  task :list_extracts => :environment do
    require 'route_extract'
    
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end
    
    manager = RouteExtract::ExtractManager.new(RouteExtract.config)
    extracts = manager.list_extracts
    
    if extracts.empty?
      puts "No extracts found."
      return
    end
    
    puts "Existing Extracts:"
    puts "-" * 80
    puts sprintf("%-30s %-20s %-15s %-10s", "Name", "Route", "Files", "Size")
    puts "-" * 80
    
    extracts.each do |extract|
      if extract[:valid]
        route_display = "#{extract[:route]['controller']}##{extract[:route]['action']}"
        puts sprintf("%-30s %-20s %-15s %-10s", 
                    extract[:name][0..29], 
                    route_display[0..19], 
                    extract[:files_count], 
                    extract[:size])
      else
        puts sprintf("%-30s %-20s %-15s %-10s", 
                    extract[:name][0..29], 
                    "INVALID", 
                    "N/A", 
                    extract[:size])
      end
    end
    
    if RouteExtract.config.verbose
      puts "\nDetailed information:"
      extracts.each do |extract|
        puts "\n#{extract[:name]}:"
        if extract[:valid]
          puts "  Route: #{extract[:route]['controller']}##{extract[:route]['action']}"
          puts "  Created: #{extract[:created_at]&.strftime('%Y-%m-%d %H:%M:%S') || 'Unknown'}"
          puts "  Files: #{extract[:files_count]}"
          puts "  Size: #{extract[:size]}"
        else
          puts "  Status: Invalid (#{extract[:error]})"
        end
      end
    end
  end

  desc "Show help for route_extract tasks"
  task :help do
    puts "RouteExtract Rake Tasks:"
    puts ""
    puts "Basic extraction:"
    puts "  rake route_extract:extract[route_pattern,mode]     # Extract code for a specific route"
    puts "  rake route_extract:extract_multiple[route1,route2] # Extract code for multiple routes"
    puts "  rake route_extract:extract_pattern[pattern]        # Extract routes matching pattern"
    puts "  rake route_extract:extract_controller[controller]  # Extract all routes for controller"
    puts ""
    puts "Management:"
    puts "  rake route_extract:list_extracts                   # List all existing extracts"
    puts "  rake route_extract:stats                           # Show extraction statistics"
    puts "  rake route_extract:cleanup                         # Clean up old extracts"
    puts ""
    puts "Route information:"
    puts "  rake route_extract:list                            # List all available routes"
    puts "  rake route_extract:info[route_pattern]             # Show route information"
    puts ""
    puts "Examples:"
    puts "  rake route_extract:extract[users#index]"
    puts "  rake route_extract:extract[users#show,mv] MODE=mv"
    puts "  rake route_extract:extract_multiple[users#index,users#show,posts#index]"
    puts "  rake route_extract:extract_controller[users]"
    puts ""
    puts "Environment variables:"
    puts "  VERBOSE=true          # Enable verbose output"
    puts "  MODE=mvc              # Extraction mode (m, v, c, mv, mc, vc, mvc)"
    puts "  INCLUDE_GEMS=false    # Include gem source files"
    puts "  INCLUDE_TESTS=true    # Include test files"
    puts "  COMPRESS=true         # Compress extracts"
    puts ""
    puts "Modes:"
    puts "  m, models             # Extract models only"
    puts "  v, views              # Extract views only"
    puts "  c, controllers        # Extract controllers only"
    puts "  mv, models_views      # Extract models and views"
    puts "  mc, models_controllers # Extract models and controllers"
    puts "  vc, views_controllers # Extract views and controllers"
    puts "  mvc, all              # Extract models, views, and controllers (default)"
  end
end

