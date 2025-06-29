# frozen_string_literal: true

namespace :route_extract do
  desc "List all available routes"
  task :list => :environment do
    require 'route_extract'
    
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end
    
    filter = ENV['FILTER']
    format = ENV['FORMAT'] || 'table'
    
    begin
      routes = RouteExtract.list_routes
      
      if filter
        routes = routes.select { |route| route[:pattern].match?(Regexp.new(filter, Regexp::IGNORECASE)) }
      end
      
      case format.downcase
      when 'json'
        require 'json'
        puts JSON.pretty_generate(routes)
      when 'csv'
        puts "Pattern,Controller,Action,Method,Name,Helper"
        routes.each do |route|
          puts "#{route[:pattern]},#{route[:controller]},#{route[:action]},#{route[:method]},#{route[:name]},#{route[:helper]}"
        end
      else
        print_routes_table(routes)
      end
      
    rescue => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.join("\n") if RouteExtract.config.verbose
      exit 1
    end
  end

  desc "Show detailed information about a route"
  task :info, [:route_pattern] => :environment do |t, args|
    require 'route_extract'
    
    route_pattern = args[:route_pattern]
    
    unless route_pattern
      puts "Usage: rake route_extract:info[route_pattern]"
      puts "Example: rake route_extract:info[users#index]"
      exit 1
    end
    
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end
    
    begin
      info = RouteExtract.route_info(route_pattern)
      
      if info
        puts "Route Information:"
        puts "  Pattern: #{info[:pattern]}"
        puts "  Controller: #{info[:controller]}"
        puts "  Action: #{info[:action]}"
        puts "  HTTP Method: #{info[:method]}"
        puts "  Route Name: #{info[:name] || 'N/A'}"
        puts "  Helper: #{info[:helper] || 'N/A'}"
        puts "  Path: #{info[:path]}"
        
        if info[:files]
          puts "\nAssociated Files:"
          
          if info[:files][:models].any?
            puts "  Models:"
            info[:files][:models].each { |file| puts "    #{file}" }
          end
          
          if info[:files][:views].any?
            puts "  Views:"
            info[:files][:views].each { |file| puts "    #{file}" }
          end
          
          if info[:files][:controllers].any?
            puts "  Controllers:"
            info[:files][:controllers].each { |file| puts "    #{file}" }
          end
          
          if info[:files][:helpers].any?
            puts "  Helpers:"
            info[:files][:helpers].each { |file| puts "    #{file}" }
          end
          
          if info[:files][:concerns].any?
            puts "  Concerns:"
            info[:files][:concerns].each { |file| puts "    #{file}" }
          end
        end
        
        # Show dependencies if verbose
        if RouteExtract.config.verbose
          analyzer = RouteExtract::RouteAnalyzer.new(RouteExtract.config)
          dependencies = analyzer.route_dependencies(route_pattern)
          
          puts "\nDependencies:"
          dependencies.each do |type, deps|
            if deps.any?
              puts "  #{type.to_s.capitalize}:"
              deps.each { |dep| puts "    #{dep}" }
            end
          end
        end
        
      else
        puts "✗ Route not found: #{route_pattern}"
        puts "Use 'rake route_extract:list' to see available routes."
        exit 1
      end
      
    rescue => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.join("\n") if RouteExtract.config.verbose
      exit 1
    end
  end

  desc "Find routes matching a pattern"
  task :find, [:pattern] => :environment do |t, args|
    require 'route_extract'
    
    pattern = args[:pattern]
    
    unless pattern
      puts "Usage: rake route_extract:find[pattern]"
      puts "Example: rake route_extract:find[users]"
      exit 1
    end
    
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end
    
    begin
      analyzer = RouteExtract::RouteAnalyzer.new(RouteExtract.config)
      routes = analyzer.find_routes_by_pattern(pattern)
      
      if routes.empty?
        puts "No routes found matching pattern: #{pattern}"
      else
        puts "Routes matching pattern '#{pattern}':"
        print_routes_table(routes)
      end
      
    rescue => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.join("\n") if RouteExtract.config.verbose
      exit 1
    end
  end

  desc "Show routes for a specific controller"
  task :controller, [:controller_name] => :environment do |t, args|
    require 'route_extract'
    
    controller_name = args[:controller_name]
    
    unless controller_name
      puts "Usage: rake route_extract:controller[controller_name]"
      puts "Example: rake route_extract:controller[users]"
      exit 1
    end
    
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end
    
    begin
      routes = RouteExtract.list_routes
      controller_routes = routes.select { |route| route[:controller] == controller_name }
      
      if controller_routes.empty?
        puts "No routes found for controller: #{controller_name}"
      else
        puts "Routes for controller '#{controller_name}':"
        print_routes_table(controller_routes)
      end
      
    rescue => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.join("\n") if RouteExtract.config.verbose
      exit 1
    end
  end

  desc "Validate route patterns"
  task :validate, [:route_patterns] => :environment do |t, args|
    require 'route_extract'
    
    route_patterns_str = args[:route_patterns]
    
    unless route_patterns_str
      puts "Usage: rake route_extract:validate[route1,route2,route3]"
      puts "Example: rake route_extract:validate[users#index,users#show,posts#index]"
      exit 1
    end
    
    route_patterns = route_patterns_str.split(',').map(&:strip)
    
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end
    
    begin
      analyzer = RouteExtract::RouteAnalyzer.new(RouteExtract.config)
      
      valid_routes = []
      invalid_routes = []
      
      route_patterns.each do |pattern|
        if analyzer.route_exists?(pattern)
          valid_routes << pattern
        else
          invalid_routes << pattern
        end
      end
      
      puts "Route Validation Results:"
      puts "  Total patterns: #{route_patterns.length}"
      puts "  Valid routes: #{valid_routes.length}"
      puts "  Invalid routes: #{invalid_routes.length}"
      
      if valid_routes.any?
        puts "\nValid routes:"
        valid_routes.each { |route| puts "  ✓ #{route}" }
      end
      
      if invalid_routes.any?
        puts "\nInvalid routes:"
        invalid_routes.each { |route| puts "  ✗ #{route}" }
      end
      
      exit 1 if invalid_routes.any?
      
    rescue => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.join("\n") if RouteExtract.config.verbose
      exit 1
    end
  end

  desc "Show route statistics"
  task :route_stats => :environment do
    require 'route_extract'
    
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end
    
    begin
      routes = RouteExtract.list_routes
      
      # Calculate statistics
      total_routes = routes.length
      controllers = routes.map { |r| r[:controller] }.uniq
      actions = routes.map { |r| r[:action] }.uniq
      methods = routes.map { |r| r[:method] }.uniq
      
      # Count by controller
      controller_counts = Hash.new(0)
      routes.each { |route| controller_counts[route[:controller]] += 1 }
      
      # Count by action
      action_counts = Hash.new(0)
      routes.each { |route| action_counts[route[:action]] += 1 }
      
      # Count by method
      method_counts = Hash.new(0)
      routes.each { |route| method_counts[route[:method]] += 1 }
      
      puts "Route Statistics:"
      puts "  Total routes: #{total_routes}"
      puts "  Unique controllers: #{controllers.length}"
      puts "  Unique actions: #{actions.length}"
      puts "  HTTP methods: #{methods.join(', ')}"
      
      puts "\nTop controllers by route count:"
      controller_counts.sort_by { |_, count| -count }.first(10).each do |controller, count|
        puts "  #{controller}: #{count} routes"
      end
      
      puts "\nTop actions by frequency:"
      action_counts.sort_by { |_, count| -count }.first(10).each do |action, count|
        puts "  #{action}: #{count} routes"
      end
      
      puts "\nHTTP method distribution:"
      method_counts.sort_by { |_, count| -count }.each do |method, count|
        puts "  #{method}: #{count} routes"
      end
      
    rescue => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.join("\n") if RouteExtract.config.verbose
      exit 1
    end
  end

  # Helper method for printing routes table
  def print_routes_table(routes)
    return puts("No routes found.") if routes.empty?
    
    puts "Available Routes:"
    puts "-" * 100
    puts sprintf("%-30s %-20s %-15s %-10s %-15s", "Pattern", "Controller", "Action", "Method", "Name")
    puts "-" * 100
    
    routes.each do |route|
      puts sprintf("%-30s %-20s %-15s %-10s %-15s", 
                  route[:pattern][0..29], 
                  route[:controller][0..19], 
                  route[:action][0..14], 
                  route[:method][0..9],
                  (route[:name] || 'N/A')[0..14])
    end
    
    puts "\nTotal: #{routes.length} routes"
  end
end

