# frozen_string_literal: true

namespace :rails_route_extractor do
  desc "Extract MVC code for a specific route"
  task :extract, [:route_pattern, :mode] => :environment do |_t, args|
    require 'rails_route_extractor'

    unless args[:route_pattern]
      puts "Usage: rake rails_route_extractor:extract[route_pattern,mode]"
      puts "Example: rake rails_route_extractor:extract[users#index,mvc]"
      puts "Available modes: mvc, m, v, c, mv, mc, vc"
      exit 1
    end

    route_pattern = args[:route_pattern]
    mode = args[:mode] || "mvc"

    puts "Extracting code for route: #{route_pattern} (mode: #{mode})"
    puts "=" * 50

    begin
      result = RailsRouteExtractor.extract_route(route_pattern, mode: mode)

      if result[:success]
        puts "✅ Successfully extracted route: #{route_pattern}"
        puts "📁 Extract location: #{result[:extract_path]}"
        puts "📄 Files extracted: #{result[:files_count]}"
        puts "💾 Total size: #{result[:total_size]}"
        
        if result[:gems_included]
          puts "💎 Gems included: #{result[:gems_included].join(', ')}"
        end
      else
        puts "❌ Failed to extract route: #{route_pattern}"
        puts "Error: #{result[:error]}"
        exit 1
      end
    rescue => e
      puts "❌ Error extracting route: #{e.message}"
      exit 1
    end
  end

  desc "Extract MVC code for multiple routes"
  task :extract_multiple, [:routes] => :environment do |_t, args|
    require 'rails_route_extractor'

    unless args[:routes]
      puts "Usage: rake rails_route_extractor:extract_multiple[route1,route2,route3]"
      puts "Example: rake rails_route_extractor:extract_multiple[users#index,users#show,posts#index]"
      exit 1
    end

    route_patterns = args[:routes].split(',')
    puts "Extracting code for #{route_patterns.length} routes: #{route_patterns.join(', ')}"
    puts "=" * 50

    begin
      result = RailsRouteExtractor.extract_routes(route_patterns)

      if result[:success]
        puts "✅ Successfully extracted #{result[:successful_count]} routes"
        puts "❌ Failed to extract #{result[:failed_count]} routes"
        puts "📄 Total files extracted: #{result[:total_files]}"
        puts "💾 Total size: #{result[:total_size]}"
        
        if result[:failed_routes]
          puts "Failed routes: #{result[:failed_routes].join(', ')}"
        end
      else
        puts "❌ Batch extraction failed"
        puts "Error: #{result[:error]}"
        exit 1
      end
    rescue => e
      puts "❌ Error in batch extraction: #{e.message}"
      exit 1
    end
  end

  desc "Extract routes matching a pattern"
  task :extract_pattern, [:pattern] => :environment do |_t, args|
    require 'rails_route_extractor'

    unless args[:pattern]
      puts "Usage: rake rails_route_extractor:extract_pattern[pattern]"
      puts "Example: rake rails_route_extractor:extract_pattern[users]"
      exit 1
    end

    pattern = args[:pattern]
    puts "Finding routes matching pattern: #{pattern}"
    puts "=" * 50

    begin
      routes = RailsRouteExtractor.list_routes
      matching_routes = routes.select { |route| route[:controller]&.include?(pattern) || route[:action]&.include?(pattern) }

      if matching_routes.empty?
        puts "❌ No routes found matching pattern: #{pattern}"
        exit 1
      end

      puts "Found #{matching_routes.length} matching routes:"
      matching_routes.each { |route| puts "  - #{route[:controller]}##{route[:action]}" }

      route_patterns = matching_routes.map { |route| "#{route[:controller]}##{route[:action]}" }
      result = RailsRouteExtractor.extract_routes(route_patterns)

      if result[:success]
        puts "✅ Successfully extracted #{result[:successful_count]} routes"
        puts "📄 Total files extracted: #{result[:total_files]}"
        puts "💾 Total size: #{result[:total_size]}"
      else
        puts "❌ Pattern extraction failed"
        puts "Error: #{result[:error]}"
        exit 1
      end
    rescue => e
      puts "❌ Error in pattern extraction: #{e.message}"
      exit 1
    end
  end

  desc "Extract all routes for a specific controller"
  task :extract_controller, [:controller_name] => :environment do |_t, args|
    require 'rails_route_extractor'

    unless args[:controller_name]
      puts "Usage: rake rails_route_extractor:extract_controller[controller_name]"
      puts "Example: rake rails_route_extractor:extract_controller[users]"
      exit 1
    end

    controller_name = args[:controller_name]
    puts "Finding all routes for controller: #{controller_name}"
    puts "=" * 50

    begin
      routes = RailsRouteExtractor.list_routes
      controller_routes = routes.select { |route| route[:controller] == controller_name }

      if controller_routes.empty?
        puts "❌ No routes found for controller: #{controller_name}"
        exit 1
      end

      puts "Found #{controller_routes.length} routes for controller #{controller_name}:"
      controller_routes.each { |route| puts "  - #{route[:controller]}##{route[:action]}" }

      route_patterns = controller_routes.map { |route| "#{route[:controller]}##{route[:action]}" }
      result = RailsRouteExtractor.extract_routes(route_patterns)

      if result[:success]
        puts "✅ Successfully extracted #{result[:successful_count]} routes"
        puts "📄 Total files extracted: #{result[:total_files]}"
        puts "💾 Total size: #{result[:total_size]}"
      else
        puts "❌ Controller extraction failed"
        puts "Error: #{result[:error]}"
        exit 1
      end
    rescue => e
      puts "❌ Error in controller extraction: #{e.message}"
      exit 1
    end
  end

  desc "Extract with custom configuration"
  task :extract_custom, [:route_pattern, :config] => :environment do |_t, args|
    require 'rails_route_extractor'

    unless args[:route_pattern]
      puts "Usage: rake rails_route_extractor:extract_custom[route_pattern,config_json]"
      puts "Example: rake rails_route_extractor:extract_custom[users#index,'{\"include_gems\":false,\"verbose\":true}']"
      exit 1
    end

    route_pattern = args[:route_pattern]
    config_json = args[:config] || "{}"

    begin
      custom_config = JSON.parse(config_json)
      puts "Extracting with custom configuration: #{custom_config}"
      puts "=" * 50

      result = RailsRouteExtractor.extract_route(route_pattern, custom_config)

      if result[:success]
        puts "✅ Successfully extracted route: #{route_pattern}"
        puts "📁 Extract location: #{result[:extract_path]}"
        puts "📄 Files extracted: #{result[:files_count]}"
        puts "💾 Total size: #{result[:total_size]}"
      else
        puts "❌ Failed to extract route: #{route_pattern}"
        puts "Error: #{result[:error]}"
        exit 1
      end
    rescue JSON::ParserError => e
      puts "❌ Invalid JSON configuration: #{e.message}"
      exit 1
    rescue => e
      puts "❌ Error in custom extraction: #{e.message}"
      exit 1
    end
  end

  desc "Show help for rails_route_extractor tasks"
  task :help do
    puts "RailsRouteExtractor Rake Tasks"
    puts "=" * 40
    puts ""
    puts "Extraction Tasks:"
    puts "  rake rails_route_extractor:extract[route_pattern,mode]     # Extract code for a specific route"
    puts "  rake rails_route_extractor:extract_multiple[route1,route2] # Extract code for multiple routes"
    puts "  rake rails_route_extractor:extract_pattern[pattern]        # Extract routes matching pattern"
    puts "  rake rails_route_extractor:extract_controller[controller]  # Extract all routes for a controller"
    puts "  rake rails_route_extractor:extract_custom[route,config]    # Extract with custom configuration"
    puts ""
    puts "Route Analysis Tasks:"
    puts "  rake rails_route_extractor:list                            # List all available routes"
    puts "  rake rails_route_extractor:info[route_pattern]             # Get detailed route information"
    puts "  rake rails_route_extractor:find[pattern]                   # Find routes matching pattern"
    puts "  rake rails_route_extractor:controller[controller_name]     # List routes for a controller"
    puts "  rake rails_route_extractor:validate[route1,route2]         # Validate route patterns"
    puts ""
    puts "Maintenance Tasks:"
    puts "  rake rails_route_extractor:cleanup[options]                # Clean up old extracts"
    puts "  rake rails_route_extractor:stats                           # Show extraction statistics"
    puts ""
    puts "Examples:"
    puts "  rake rails_route_extractor:extract[users#index,mvc]"
    puts "  rake rails_route_extractor:extract_multiple[users#index,posts#show]"
    puts "  rake rails_route_extractor:list"
    puts "  rake rails_route_extractor:cleanup[older_than:7d]"
  end
end

