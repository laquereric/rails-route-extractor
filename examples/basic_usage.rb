#!/usr/bin/env ruby
# frozen_string_literal: true

# Basic RouteExtract Usage Examples
# 
# This file demonstrates common usage patterns for the RouteExtract gem.
# Run these examples in a Rails application with RouteExtract installed.

require 'route_extract'

puts "RouteExtract Basic Usage Examples"
puts "=" * 50

# Example 1: Basic Configuration
puts "\n1. Basic Configuration"
puts "-" * 30

RouteExtract.configure do |config|
  config.verbose = true
  config.include_gems = true
  config.include_tests = false
  config.extract_base_path = "examples/extracts"
end

puts "✓ Configuration set with verbose output enabled"

# Example 2: List Available Routes
puts "\n2. List Available Routes"
puts "-" * 30

begin
  routes = RouteExtract.list_routes
  puts "Found #{routes.length} routes in the application:"
  
  # Show first 5 routes as example
  routes.first(5).each do |route|
    puts "  #{route[:controller]}##{route[:action]} (#{route[:method]})"
  end
  
  if routes.length > 5
    puts "  ... and #{routes.length - 5} more routes"
  end
rescue => e
  puts "⚠ Error listing routes: #{e.message}"
  puts "  Make sure you're running this in a Rails application"
end

# Example 3: Get Route Information
puts "\n3. Get Route Information"
puts "-" * 30

route_pattern = "users#index"  # Change this to match your application
begin
  info = RouteExtract.route_info(route_pattern)
  
  if info
    puts "Route Information for '#{route_pattern}':"
    puts "  Pattern: #{info[:pattern]}"
    puts "  Controller: #{info[:controller]}"
    puts "  Action: #{info[:action]}"
    puts "  HTTP Method: #{info[:method]}"
    puts "  Helper: #{info[:helper] || 'N/A'}"
    
    if info[:files]
      puts "  Associated Files:"
      info[:files].each do |type, files|
        if files.any?
          puts "    #{type.to_s.capitalize}: #{files.length} files"
        end
      end
    end
  else
    puts "⚠ Route '#{route_pattern}' not found"
    puts "  Available routes: #{RouteExtract.list_routes.map { |r| "#{r[:controller]}##{r[:action]}" }.first(3).join(', ')}"
  end
rescue => e
  puts "⚠ Error getting route info: #{e.message}"
end

# Example 4: Basic Route Extraction
puts "\n4. Basic Route Extraction"
puts "-" * 30

begin
  result = RouteExtract.extract_route(route_pattern, mode: "mvc")
  
  if result[:success]
    puts "✓ Successfully extracted route '#{route_pattern}'"
    puts "  Extract path: #{result[:extract_path]}"
    puts "  Files extracted: #{result[:files_count]}"
    puts "  Total size: #{result[:total_size]}"
  else
    puts "✗ Extraction failed: #{result[:error]}"
  end
rescue => e
  puts "⚠ Error during extraction: #{e.message}"
end

# Example 5: Extract with Different Modes
puts "\n5. Extract with Different Modes"
puts "-" * 30

modes = %w[m v c mv mc vc mvc]
modes.each do |mode|
  begin
    result = RouteExtract.extract_route(route_pattern, mode: mode)
    
    if result[:success]
      puts "✓ Mode '#{mode}': #{result[:files_count]} files, #{result[:total_size]}"
    else
      puts "✗ Mode '#{mode}': #{result[:error]}"
    end
  rescue => e
    puts "⚠ Mode '#{mode}': #{e.message}"
  end
end

# Example 6: Extract Multiple Routes
puts "\n6. Extract Multiple Routes"
puts "-" * 30

# Get first 3 routes for demonstration
begin
  available_routes = RouteExtract.list_routes.first(3)
  route_patterns = available_routes.map { |r| "#{r[:controller]}##{r[:action]}" }
  
  puts "Extracting routes: #{route_patterns.join(', ')}"
  
  result = RouteExtract.extract_routes(route_patterns, mode: "mvc")
  
  if result[:success]
    puts "✓ Batch extraction completed"
    puts "  Successful: #{result[:successful_count]}"
    puts "  Failed: #{result[:failed_count]}"
    puts "  Total files: #{result[:total_files]}"
    puts "  Total size: #{result[:total_size]}"
  else
    puts "✗ Batch extraction failed: #{result[:error]}"
  end
rescue => e
  puts "⚠ Error during batch extraction: #{e.message}"
end

# Example 7: Using Extract Manager
puts "\n7. Using Extract Manager"
puts "-" * 30

begin
  manager = RouteExtract::ExtractManager.new(RouteExtract.config)
  
  # Get extraction statistics
  stats = manager.extraction_statistics
  puts "Extraction Statistics:"
  puts "  Total extracts: #{stats[:extracts_count]}"
  puts "  Total size: #{stats[:total_size]}"
  puts "  Oldest: #{stats[:oldest]&.strftime('%Y-%m-%d %H:%M') || 'N/A'}"
  puts "  Newest: #{stats[:newest]&.strftime('%Y-%m-%d %H:%M') || 'N/A'}"
  
  # List existing extracts
  extracts = manager.list_extracts
  if extracts.any?
    puts "\nExisting Extracts:"
    extracts.first(3).each do |extract|
      if extract[:valid]
        puts "  #{extract[:name]}: #{extract[:route]['controller']}##{extract[:route]['action']}"
      else
        puts "  #{extract[:name]}: INVALID (#{extract[:error]})"
      end
    end
  else
    puts "\nNo existing extracts found"
  end
rescue => e
  puts "⚠ Error with extract manager: #{e.message}"
end

# Example 8: Route Analysis
puts "\n8. Route Analysis"
puts "-" * 30

begin
  analyzer = RouteExtract::RouteAnalyzer.new(RouteExtract.config)
  
  # Find routes by pattern
  admin_routes = analyzer.find_routes_by_pattern("admin")
  puts "Found #{admin_routes.length} admin routes"
  
  # Get route dependencies
  if RouteExtract.list_routes.any?
    sample_route = RouteExtract.list_routes.first
    pattern = "#{sample_route[:controller]}##{sample_route[:action]}"
    
    dependencies = analyzer.route_dependencies(pattern)
    puts "\nDependencies for '#{pattern}':"
    dependencies.each do |type, deps|
      if deps.any?
        puts "  #{type.to_s.capitalize}: #{deps.length} items"
      end
    end
  end
rescue => e
  puts "⚠ Error during route analysis: #{e.message}"
end

# Example 9: Cleanup Operations
puts "\n9. Cleanup Operations"
puts "-" * 30

begin
  manager = RouteExtract::ExtractManager.new(RouteExtract.config)
  
  # Simulate cleanup (with force to avoid prompts)
  result = manager.cleanup_extracts(force: true, older_than: "1d")
  
  if result[:success]
    puts "✓ Cleanup completed"
    puts "  Removed: #{result[:removed_count]} extracts"
    puts "  Space freed: #{result[:space_freed]}"
  else
    puts "✗ Cleanup failed: #{result[:error]}"
  end
rescue => e
  puts "⚠ Error during cleanup: #{e.message}"
end

puts "\n" + "=" * 50
puts "Examples completed!"
puts "\nNext steps:"
puts "1. Try running individual examples with your application's routes"
puts "2. Explore the CLI: route_extract help"
puts "3. Check out the rake tasks: rake route_extract:help"
puts "4. Read the full documentation in docs/user_guide.md"

