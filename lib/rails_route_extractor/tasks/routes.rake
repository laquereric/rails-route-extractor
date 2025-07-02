# frozen_string_literal: true
puts "routes.rake"
namespace :rails_route_extractor do
  namespace :list do
    desc "List all available routes in text format"
    task :text, [:pattern, :controller, :method] => :environment do |_t, args|
      require 'rails_route_extractor'

      puts "Available Routes:"
      puts "=" * 80
      puts sprintf("%-20s %-15s %-20s %-10s %-15s", "Controller", "Action", "Path", "Method", "Name")
      puts "=" * 80

      begin
        routes = get_filtered_routes(args)

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
end

