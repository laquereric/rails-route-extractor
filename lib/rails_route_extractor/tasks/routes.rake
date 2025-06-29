# frozen_string_literal: true

namespace :rails_route_extractor do
  desc "List all available routes"
  task :list => :environment do
    require 'rails_route_extractor'

    puts "Available Routes:"
    puts "=" * 80
    puts sprintf("%-20s %-15s %-20s %-10s %-15s", "Controller", "Action", "Path", "Method", "Name")
    puts "=" * 80

    begin
      routes = RailsRouteExtractor.list_routes

      if routes.empty?
        puts "No routes found."
        exit 1
      end

      routes.each do |route|
        controller = route[:controller] || "N/A"
        action = route[:action] || "N/A"
        path = route[:path] || "N/A"
        method = route[:method] || "GET"
        name = route[:name] || "N/A"

        puts sprintf("%-20s %-15s %-20s %-10s %-15s", 
                    controller[0..19], 
                    action[0..14], 
                    path[0..19], 
                    method, 
                    name[0..14])
      end

      puts "=" * 80
      puts "Total routes: #{routes.length}"
    rescue => e
      puts "❌ Error listing routes: #{e.message}"
      exit 1
    end
  end

  desc "Get detailed information about a specific route"
  task :info, [:route_pattern] => :environment do |_t, args|
    require 'rails_route_extractor'

    unless args[:route_pattern]
      puts "Usage: rake rails_route_extractor:info[route_pattern]"
      puts "Example: rake rails_route_extractor:info[users#index]"
      exit 1
    end

    route_pattern = args[:route_pattern]
    puts "Route Information for: #{route_pattern}"
    puts "=" * 50

    begin
      info = RailsRouteExtractor.route_info(route_pattern)

      if info
        puts "Controller: #{info[:controller]}"
        puts "Action: #{info[:action]}"
        puts "Path: #{info[:path]}"
        puts "Method: #{info[:method]}"
        puts "Name: #{info[:name]}"
        
        if info[:files]
          puts "\nAssociated Files:"
          if info[:files][:models]&.any?
            puts "  Models:"
            info[:files][:models].each { |file| puts "    - #{file}" }
          end
          if info[:files][:views]&.any?
            puts "  Views:"
            info[:files][:views].each { |file| puts "    - #{file}" }
          end
          if info[:files][:controllers]&.any?
            puts "  Controllers:"
            info[:files][:controllers].each { |file| puts "    - #{file}" }
          end
        end
      else
        puts "❌ Route not found: #{route_pattern}"
        puts "Use 'rake rails_route_extractor:list' to see available routes."
        exit 1
      end
    rescue => e
      puts "❌ Error getting route info: #{e.message}"
      exit 1
    end
  end

  desc "Find routes matching a pattern"
  task :find, [:pattern] => :environment do |_t, args|
    require 'rails_route_extractor'

    unless args[:pattern]
      puts "Usage: rake rails_route_extractor:find[pattern]"
      puts "Example: rake rails_route_extractor:find[users]"
      exit 1
    end

    pattern = args[:pattern]
    puts "Finding routes matching pattern: #{pattern}"
    puts "=" * 50

    begin
      routes = RailsRouteExtractor.list_routes
      matching_routes = routes.select { |route| 
        route[:controller]&.include?(pattern) || 
        route[:action]&.include?(pattern) || 
        route[:path]&.include?(pattern) ||
        route[:name]&.include?(pattern)
      }

      if matching_routes.empty?
        puts "❌ No routes found matching pattern: #{pattern}"
        exit 1
      end

      puts "Found #{matching_routes.length} matching routes:"
      puts sprintf("%-20s %-15s %-20s %-10s", "Controller", "Action", "Path", "Method")
      puts "-" * 70

      matching_routes.each do |route|
        controller = route[:controller] || "N/A"
        action = route[:action] || "N/A"
        path = route[:path] || "N/A"
        method = route[:method] || "GET"

        puts sprintf("%-20s %-15s %-20s %-10s", 
                    controller[0..19], 
                    action[0..14], 
                    path[0..19], 
                    method)
      end
    rescue => e
      puts "❌ Error finding routes: #{e.message}"
      exit 1
    end
  end

  desc "List all routes for a specific controller"
  task :controller, [:controller_name] => :environment do |_t, args|
    require 'rails_route_extractor'

    unless args[:controller_name]
      puts "Usage: rake rails_route_extractor:controller[controller_name]"
      puts "Example: rake rails_route_extractor:controller[users]"
      exit 1
    end

    controller_name = args[:controller_name]
    puts "Routes for controller: #{controller_name}"
    puts "=" * 50

    begin
      routes = RailsRouteExtractor.list_routes
      controller_routes = routes.select { |route| route[:controller] == controller_name }

      if controller_routes.empty?
        puts "❌ No routes found for controller: #{controller_name}"
        exit 1
      end

      puts "Found #{controller_routes.length} routes:"
      puts sprintf("%-15s %-20s %-10s %-15s", "Action", "Path", "Method", "Name")
      puts "-" * 65

      controller_routes.each do |route|
        action = route[:action] || "N/A"
        path = route[:path] || "N/A"
        method = route[:method] || "GET"
        name = route[:name] || "N/A"

        puts sprintf("%-15s %-20s %-10s %-15s", 
                    action[0..14], 
                    path[0..19], 
                    method, 
                    name[0..14])
      end
    rescue => e
      puts "❌ Error listing controller routes: #{e.message}"
      exit 1
    end
  end

  desc "Validate route patterns"
  task :validate, [:routes] => :environment do |_t, args|
    require 'rails_route_extractor'

    unless args[:routes]
      puts "Usage: rake rails_route_extractor:validate[route1,route2,route3]"
      puts "Example: rake rails_route_extractor:validate[users#index,users#show,posts#index]"
      exit 1
    end

    route_patterns = args[:routes].split(',')
    puts "Validating #{route_patterns.length} route patterns..."
    puts "=" * 50

    begin
      routes = RailsRouteExtractor.list_routes
      available_routes = routes.map { |route| "#{route[:controller]}##{route[:action]}" }

      valid_routes = []
      invalid_routes = []

      route_patterns.each do |pattern|
        if available_routes.include?(pattern)
          valid_routes << pattern
        else
          invalid_routes << pattern
        end
      end

      puts "✅ Valid routes (#{valid_routes.length}):"
      valid_routes.each { |route| puts "  - #{route}" }

      if invalid_routes.any?
        puts "\n❌ Invalid routes (#{invalid_routes.length}):"
        invalid_routes.each { |route| puts "  - #{route}" }
        puts "\nUse 'rake rails_route_extractor:list' to see available routes."
      end

      if invalid_routes.any?
        exit 1
      else
        puts "\n🎉 All route patterns are valid!"
      end
    rescue => e
      puts "❌ Error validating routes: #{e.message}"
      exit 1
    end
  end

  desc "Show route statistics"
  task :stats => :environment do
    require 'rails_route_extractor'

    puts "Route Statistics"
    puts "=" * 30

    begin
      routes = RailsRouteExtractor.list_routes

      if routes.empty?
        puts "No routes found."
        exit 1
      end

      # Count by controller
      controller_counts = routes.group_by { |route| route[:controller] }
                               .transform_values(&:length)
                               .sort_by { |_controller, count| -count }

      # Count by HTTP method
      method_counts = routes.group_by { |route| route[:method] || "GET" }
                           .transform_values(&:length)
                           .sort_by { |_method, count| -count }

      puts "Total routes: #{routes.length}"
      puts "\nRoutes by controller:"
      controller_counts.each do |controller, count|
        puts "  #{controller}: #{count}"
      end

      puts "\nRoutes by HTTP method:"
      method_counts.each do |method, count|
        puts "  #{method}: #{count}"
      end

      # Show some examples
      puts "\nExample routes:"
      routes.first(5).each do |route|
        puts "  #{route[:controller]}##{route[:action]} (#{route[:method] || 'GET'})"
      end

      if routes.length > 5
        puts "  ... and #{routes.length - 5} more"
      end
    rescue => e
      puts "❌ Error getting route statistics: #{e.message}"
      exit 1
    end
  end
end

