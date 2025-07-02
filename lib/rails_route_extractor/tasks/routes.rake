# frozen_string_literal: true
puts "routes.rake"
namespace :rails_route_extractor do
  desc "Show help for rails_route_extractor tasks"
  task :help do
    puts "Usage: rake rails_route_extractor:<command>"
    puts ""
    puts "Available commands:"
    puts "  list             - List all routes. For options, run: rake rails_route_extractor:list:help"
    puts "  catalog          - Create a route catalog. For options, run: rake rails_route_extractor:catalog:help"
    puts "  stats            - Show route statistics."
    puts "  validate         - Validate route patterns."
    puts "  help             - Show this help message."
  end

  desc "List all available routes in text format (default). See other formats under list namespace."
  task :list, [:pattern, :controller, :method] => :environment do |_t, args|
    Rake::Task['rails_route_extractor:list:text'].invoke(args[:pattern], args[:controller], args[:method])
    Rake::Task['rails_route_extractor:list:text'].reenable
  end

  namespace :list do
    desc "Show help for the list tasks"
    task :help do
      puts "Usage: rake rails_route_extractor:list:<format>[pattern,controller,method,detailed]"
      puts ""
      puts "Lists available routes in various formats with filtering options."
      puts ""
      puts "Available formats: text, json, csv, html"
      puts ""
      puts "Arguments:"
      puts "  pattern:      (Optional) Filter routes by a pattern in controller, action, path, or name."
      puts "  controller:   (Optional) Filter routes by a specific controller name."
      puts "  method:       (Optional) Filter routes by an HTTP method (e.g., GET, POST)."
      puts "  detailed:     (Optional, for json/html) Set to 'true' to include detailed file association info."
      puts ""
      puts "Examples:"
      puts "  # List all routes in text format"
      puts "  rake rails_route_extractor:list:text"
      puts ""
      puts "  # List routes containing 'user' in JSON format"
      puts "  rake rails_route_extractor:list:json[user]"
      puts ""
      puts "  # List GET routes for 'posts_controller' in HTML with details"
      puts "  rake rails_route_extractor:list:html[,posts_controller,GET,true]"
    end

    desc "List all available routes in text format"
    task :text, [:pattern, :controller, :method] => :environment do |_t, args|
      require 'rails_route_extractor'

      routes = get_filtered_routes(args)

      # Determine column widths
      controller_width = (routes.map { |r| r[:controller]&.length || 0 } + ["Controller".length]).max + 2
      action_width = (routes.map { |r| r[:action]&.length || 0 } + ["Action".length]).max + 2
      path_width = (routes.map { |r| r[:path]&.length || 0 } + ["Path".length]).max + 2
      method_width = (routes.map { |r| r[:method]&.length || 0 } + ["Method".length]).max + 2
      name_width = (routes.map { |r| r[:name]&.length || 0 } + ["Name".length]).max + 2
      total_width = controller_width + action_width + path_width + method_width + name_width

      header_format = "%-#{controller_width}s%-#{action_width}s%-#{path_width}s%-#{method_width}s%-#{name_width}s"
      row_format = "%-#{controller_width}s%-#{action_width}s%-#{path_width}s%-#{method_width}s%-#{name_width}s"

      puts "Available Routes:"
      puts "=" * total_width
      puts sprintf(header_format, "Controller", "Action", "Path", "Method", "Name")
      puts "=" * total_width

      if routes.empty?
        puts "No routes found."
        exit 1
      end

      routes.each do |route|
        puts sprintf(row_format,
                    route[:controller] || "N/A",
                    route[:action] || "N/A",
                    route[:path] || "N/A",
                    route[:method] || "GET",
                    route[:name] || "N/A")
      end

      puts "=" * total_width
      puts "Total routes: #{routes.length}"
    rescue => e
      puts "❌ Error listing routes: #{e.message}"
      exit 1
    end

    desc "List all available routes in JSON format"
    task :json, [:pattern, :controller, :method, :detailed] => :environment do |_t, args|
      require 'rails_route_extractor'
      require 'json'

      begin
        routes = get_filtered_routes(args)
        
        if args[:detailed] == 'true'
          detailed_routes = routes.map do |route|
            route_pattern = "#{route[:controller]}##{route[:action]}"
            info = RailsRouteExtractor.route_info(route_pattern) rescue nil
            route.merge(detailed_info: info)
          end
          puts JSON.pretty_generate(detailed_routes)
        else
          puts JSON.pretty_generate(routes)
        end
      rescue => e
        puts JSON.generate({ error: e.message })
        exit 1
      end
    end

    desc "List all available routes in CSV format"
    task :csv, [:pattern, :controller, :method] => :environment do |_t, args|
      require 'rails_route_extractor'
      require 'csv'

      begin
        routes = get_filtered_routes(args)
        
        CSV.generate do |csv|
          csv << ["Controller", "Action", "Path", "Method", "Name"]
          routes.each do |route|
            csv << [
              route[:controller] || "N/A",
              route[:action] || "N/A", 
              route[:path] || "N/A",
              route[:method] || "GET",
              route[:name] || "N/A"
            ]
          end
        end.tap { |output| puts output }
      rescue => e
        puts "Error,#{e.message}"
        exit 1
      end
    end

    desc "List all available routes in HTML format"
    task :html, [:pattern, :controller, :method, :detailed] => :environment do |_t, args|
      require 'rails_route_extractor'

      begin
        routes = get_filtered_routes(args)
        
        puts generate_html_routes(routes, args[:detailed] == 'true')
      rescue => e
        puts "<html><body><h1>Error</h1><p>#{e.message}</p></body></html>"
        exit 1
      end
    end
  end

  # Helper method to filter routes based on arguments
  def get_filtered_routes(args)
    routes = RailsRouteExtractor.list_routes
    
    # Filter by pattern if provided
    if args[:pattern]
      routes = routes.select { |route| 
        route[:controller]&.include?(args[:pattern]) || 
        route[:action]&.include?(args[:pattern]) || 
        route[:path]&.include?(args[:pattern]) ||
        route[:name]&.include?(args[:pattern])
      }
    end
    
    # Filter by controller if provided
    if args[:controller]
      routes = routes.select { |route| route[:controller] == args[:controller] }
    end
    
    # Filter by HTTP method if provided
    if args[:method]
      routes = routes.select { |route| route[:method] == args[:method].upcase }
    end
    
    routes
  end

  # Helper method to generate HTML output
  def generate_html_routes(routes, detailed = false)
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Rails Routes</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 20px; }
          table { border-collapse: collapse; width: 100%; }
          th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
          th { background-color: #f2f2f2; }
          tr:nth-child(even) { background-color: #f9f9f9; }
          .details { font-size: 0.9em; color: #666; }
        </style>
      </head>
      <body>
        <h1>Rails Routes (#{routes.length} total)</h1>
        <table>
          <thead>
            <tr>
              <th>Controller</th>
              <th>Action</th>
              <th>Path</th>
              <th>Method</th>
              <th>Name</th>
    HTML

    if detailed
      html += "<th>Details</th>"
    end

    html += <<~HTML
            </tr>
          </thead>
          <tbody>
    HTML

    routes.each do |route|
      html += "<tr>"
      html += "<td>#{route[:controller] || 'N/A'}</td>"
      html += "<td>#{route[:action] || 'N/A'}</td>"
      html += "<td>#{route[:path] || 'N/A'}</td>"
      html += "<td>#{route[:method] || 'GET'}</td>"
      html += "<td>#{route[:name] || 'N/A'}</td>"
      
      if detailed
        route_pattern = "#{route[:controller]}##{route[:action]}"
        info = RailsRouteExtractor.route_info(route_pattern) rescue nil
        if info && info[:files]
          details = []
          if info[:files][:models]&.any?
            details << "Models: #{info[:files][:models].join(', ')}"
          end
          if info[:files][:views]&.any?
            details << "Views: #{info[:files][:views].join(', ')}"
          end
          if info[:files][:controllers]&.any?
            details << "Controllers: #{info[:files][:controllers].join(', ')}"
          end
          html += "<td class='details'>#{details.join('<br>')}</td>"
        else
          html += "<td class='details'>No additional info</td>"
        end
      end
      
      html += "</tr>"
    end

    html += <<~HTML
          </tbody>
        </table>
      </body>
      </html>
    HTML

    html
  end

  # Helper method to parse parameter paths from string
  def parse_param_paths(param_paths_str)
    return ['controller', 'action'] if param_paths_str.nil? || param_paths_str.strip.empty?
    
    # Handle both comma-separated and array-like syntax
    param_paths_str = param_paths_str.gsub(/[\[\]'"]/, '').strip
    param_paths_str.split(',').map(&:strip).reject(&:empty?)
  end

  # Helper method to build a parameter-based catalog
  def build_param_catalog(routes, param_paths)
    catalog = {}
    
    routes.each do |route|
      current_level = catalog
      
      # Navigate through the parameter hierarchy
      param_paths.each_with_index do |param, index|
        key = route[param.to_sym] || 'unknown'
        
        if index == param_paths.length - 1
          # Last level - store the routes
          current_level[key] ||= []
          current_level[key] << route
        else
          # Intermediate level - create nested structure
          current_level[key] ||= {}
          current_level = current_level[key]
        end
      end
    end
    
    catalog
  end

  # Helper method to print text catalog
  def print_text_catalog(catalog, param_paths, level = 0)
    catalog.each do |key, value|
      indent = "  " * level
      
      if value.is_a?(Array)
        # Leaf level - print routes
        puts "#{indent}#{param_paths[level]}: #{key} (#{value.length} routes)"
        value.each do |route|
          route_info = "#{route[:method] || 'GET'} #{route[:path]} -> #{route[:controller]}##{route[:action]}"
          puts "#{indent}  - #{route_info}"
        end
      else
        # Branch level - recurse
        puts "#{indent}#{param_paths[level]}: #{key}"
        print_text_catalog(value, param_paths, level + 1)
      end
      puts if level == 0 # Add blank line between top-level items
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
        puts "\nUse 'rake rails_route_extractor:list:text' to see available routes."
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

  desc "Catalog routes by controller and action in text format (default). See other formats under catalog:by_param namespace."
  task :catalog, [:param_paths, :pattern, :controller, :method] => :environment do |_t, args|
    Rake::Task['rails_route_extractor:catalog:by_param:text'].invoke(args[:param_paths], args[:pattern], args[:controller], args[:method])
    Rake::Task['rails_route_extractor:catalog:by_param:text'].reenable
  end

  namespace :catalog do
    desc "Show help for the catalog tasks"
    task :help do
      puts "Usage: rake rails_route_extractor:catalog:by_param:<format>[param_paths,pattern,controller,method]"
      puts ""
      puts "Creates a hierarchical catalog of routes organized by one or more parameters."
      puts ""
      puts "Available formats: text, json, html, yaml"
      puts ""
      puts "Arguments:"
      puts "  param_paths:  A comma-separated string of parameters to create the hierarchy."
      puts "                Example: 'controller,action' or '[controller,action]'"
      puts "                Defaults to 'controller,action' if not provided."
      puts "  pattern:      (Optional) Filter routes by a pattern in controller, action, path, or name."
      puts "  controller:   (Optional) Filter routes by a specific controller name."
      puts "  method:       (Optional) Filter routes by an HTTP method (e.g., GET, POST)."
      puts ""
      puts "Examples:"
      puts "  # Catalog by controller, then action, in text format"
      puts "  rake rails_route_extractor:catalog:by_param:text[controller,action]"
      puts ""
      puts "  # Catalog by HTTP method, then controller, for GET requests, in JSON format"
      puts "  rake rails_route_extractor:catalog:by_param:json['method,controller',,GET]"
      puts ""
      puts "  # Catalog by controller for routes matching 'admin', in HTML format"
      puts "  rake rails_route_extractor:catalog:by_param:html[controller,admin]"
    end
    
    namespace :by_param do
      desc "Catalog routes by parameter hierarchy in text format"
      task :text, [:param_paths, :pattern, :controller, :method] => :environment do |_t, args|
        require 'rails_route_extractor'

        begin
          param_paths = parse_param_paths(args[:param_paths])
          routes = get_filtered_routes(args)
          catalog = build_param_catalog(routes, param_paths)
          
          puts "Route Catalog by #{param_paths.join(' > ')}"
          puts "=" * 80
          puts "Total routes: #{routes.length}"
          puts "=" * 80
          
          print_text_catalog(catalog, param_paths)
        rescue => e
          puts "❌ Error creating catalog: #{e.message}"
          exit 1
        end
      end

      desc "Catalog routes by parameter hierarchy in JSON format"
      task :json, [:param_paths, :pattern, :controller, :method, :detailed] => :environment do |_t, args|
        require 'rails_route_extractor'
        require 'json'

        begin
          param_paths = parse_param_paths(args[:param_paths])
          routes = get_filtered_routes(args)
          catalog = build_param_catalog(routes, param_paths)
          
          output = {
            param_hierarchy: param_paths,
            total_routes: routes.length,
            catalog: catalog
          }
          
          if args[:detailed] == 'true'
            output[:routes] = routes
          end
          
          puts JSON.pretty_generate(output)
        rescue => e
          puts JSON.generate({ error: e.message })
          exit 1
        end
      end

      desc "Catalog routes by parameter hierarchy in HTML format"
      task :html, [:param_paths, :pattern, :controller, :method] => :environment do |_t, args|
        require 'rails_route_extractor'

        begin
          param_paths = parse_param_paths(args[:param_paths])
          routes = get_filtered_routes(args)
          catalog = build_param_catalog(routes, param_paths)
          
          html_output = generate_html_catalog(catalog, param_paths, routes.length)
          puts html_output
        rescue => e
          puts "<html><body><h1>Error</h1><p>#{e.message}</p></body></html>"
          exit 1
        end
      end

      desc "Catalog routes by parameter hierarchy in YAML format"
      task :yaml, [:param_paths, :pattern, :controller, :method] => :environment do |_t, args|
        require 'rails_route_extractor'
        require 'yaml'

        begin
          param_paths = parse_param_paths(args[:param_paths])
          routes = get_filtered_routes(args)
          catalog = build_param_catalog(routes, param_paths)
          
          output = {
            param_hierarchy: param_paths,
            total_routes: routes.length,
            catalog: catalog
          }
          
          puts output.to_yaml
        rescue => e
          puts ({ error: e.message }).to_yaml
          exit 1
        end
      end
    end
  end

  # Helper method to generate HTML output for catalog
  def generate_html_catalog(catalog, param_paths, total_routes, level = 0)
    html = ""
    if level == 0
      html += <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>Route Catalog</title>
          <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .catalog { list-style-type: none; padding-left: 20px; }
            .catalog-item { margin-bottom: 10px; }
            .catalog-key { font-weight: bold; }
            .route-list { list-style-type: none; padding-left: 20px; }
            .route-item { margin-top: 5px; }
          </style>
        </head>
        <body>
          <h1>Route Catalog by #{param_paths.join(' > ')}</h1>
          <p>Total routes: #{total_routes}</p>
      HTML
    end

    html += "<ul class='catalog'>"
    catalog.each do |key, value|
      html += "<li class='catalog-item'>"
      html += "<span class='catalog-key'>#{param_paths[level]}: #{key}</span>"
      
      if value.is_a?(Array)
        html += "<ul class='route-list'>"
        value.each do |route|
          route_info = "#{route[:method] || 'GET'} #{route[:path]} -> #{route[:controller]}##{route[:action]}"
          html += "<li class='route-item'>#{route_info}</li>"
        end
        html += "</ul>"
      else
        html += generate_html_catalog(value, param_paths, total_routes, level + 1)
      end
      html += "</li>"
    end
    html += "</ul>"

    if level == 0
      html += <<~HTML
        </body>
        </html>
      HTML
    end
    html
  end
end

