# frozen_string_literal: true

require 'fileutils'
require 'find'

module RailsRouteExtractor
  class ExtractManager
    attr_reader :config, :route_analyzer, :code_extractor, :dependency_tracker

    def initialize(config)
      @config = config
      @route_analyzer = RouteAnalyzer.new(config)
      @code_extractor = CodeExtractor.new(config)
      @dependency_tracker = DependencyTracker.new(config)
    end

    # Extract code for a single route
    def extract_route(route_pattern, options = {})
      validate_extraction_environment!
      
      puts "Starting extraction for route: #{route_pattern}" if config.verbose
      
      # Validate route exists
      unless route_analyzer.route_exists?(route_pattern)
        return {
          success: false,
          error: "Route not found: #{route_pattern}. Use 'route_extract list' to see available routes."
        }
      end
      
      # Perform extraction
      result = code_extractor.extract_route(route_pattern, options)
      
      if result[:success]
        puts "✓ Extraction completed successfully" if config.verbose
        puts "  Extract location: #{result[:extract_path]}" if config.verbose
        puts "  Files extracted: #{result[:files_count]}" if config.verbose
        puts "  Total size: #{result[:total_size]}" if config.verbose
      else
        puts "✗ Extraction failed: #{result[:error]}" if config.verbose
      end
      
      result
    end

    # Extract code for multiple routes
    def extract_routes(route_patterns, options = {})
      validate_extraction_environment!
      
      puts "Starting batch extraction for #{route_patterns.length} routes" if config.verbose
      
      # Validate all routes exist first
      missing_routes = route_patterns.reject { |pattern| route_analyzer.route_exists?(pattern) }
      
      if missing_routes.any?
        return {
          success: false,
          error: "Routes not found: #{missing_routes.join(', ')}. Use 'route_extract list' to see available routes."
        }
      end
      
      # Perform batch extraction
      result = code_extractor.extract_routes(route_patterns, options)
      
      if config.verbose
        if result[:success]
          puts "✓ Batch extraction completed successfully"
        else
          puts "✗ Batch extraction completed with errors"
        end
        puts "  Successful: #{result[:successful_count]}"
        puts "  Failed: #{result[:failed_count]}"
        puts "  Total files: #{result[:total_files]}"
        puts "  Total size: #{result[:total_size]}"
      end
      
      result
    end

    # Extract all routes matching a pattern
    def extract_routes_by_pattern(pattern, options = {})
      matching_routes = route_analyzer.find_routes_by_pattern(pattern)
      
      if matching_routes.empty?
        return {
          success: false,
          error: "No routes found matching pattern: #{pattern}"
        }
      end
      
      route_patterns = matching_routes.map { |route| "#{route[:controller]}##{route[:action]}" }
      extract_routes(route_patterns, options)
    end

    # Extract routes for a specific controller
    def extract_controller_routes(controller_name, options = {})
      extract_routes_by_pattern("#{controller_name}#", options)
    end

    # Get extraction statistics
    def extraction_statistics
      extract_base = config.full_extract_path
      return { extracts_count: 0, total_size: 0, oldest: nil, newest: nil } unless Dir.exist?(extract_base)
      
      extracts = Dir.glob(File.join(extract_base, '*')).select { |path| File.directory?(path) }
      
      total_size = 0
      timestamps = []
      
      extracts.each do |extract_path|
        size = calculate_directory_size(extract_path)
        total_size += size
        
        # Extract timestamp from directory name
        basename = File.basename(extract_path)
        if basename.match(/_(\d{8}_\d{6})$/)
          timestamp = DateTime.strptime($1, '%Y%m%d_%H%M%S')
          timestamps << timestamp
        end
      end
      
      {
        extracts_count: extracts.length,
        total_size: format_size(total_size),
        oldest: timestamps.min,
        newest: timestamps.max,
        extract_paths: extracts
      }
    end

    # Clean up old extracts
    def cleanup_extracts(options = {})
      extract_base = config.full_extract_path
      return { success: true, removed_count: 0, space_freed: 0 } unless Dir.exist?(extract_base)
      
      extracts = Dir.glob(File.join(extract_base, '*')).select { |path| File.directory?(path) }
      
      # Filter extracts to remove
      extracts_to_remove = []
      
      if options[:older_than]
        cutoff_time = parse_time_duration(options[:older_than])
        
        extracts.each do |extract_path|
          basename = File.basename(extract_path)
          if basename.match(/_(\d{8}_\d{6})$/)
            timestamp = DateTime.strptime($1, '%Y%m%d_%H%M%S')
            if timestamp < cutoff_time
              extracts_to_remove << extract_path
            end
          end
        end
      elsif options[:keep_latest]
        # Keep only the N most recent extracts
        keep_count = options[:keep_latest].to_i
        sorted_extracts = extracts.sort_by do |extract_path|
          basename = File.basename(extract_path)
          if basename.match(/_(\d{8}_\d{6})$/)
            DateTime.strptime($1, '%Y%m%d_%H%M%S')
          else
            DateTime.new(1970, 1, 1) # Very old date for extracts without timestamp
          end
        end
        
        extracts_to_remove = sorted_extracts[0...-keep_count] if sorted_extracts.length > keep_count
      else
        # Remove all extracts if no specific criteria
        extracts_to_remove = extracts
      end
      
      return { success: true, removed_count: 0, space_freed: 0 } if extracts_to_remove.empty?
      
      # Confirm removal unless forced
      unless options[:force]
        puts "The following extracts will be removed:"
        extracts_to_remove.each { |path| puts "  #{File.basename(path)}" }
        print "Continue? (y/N): "
        response = STDIN.gets.chomp.downcase
        return { success: false, error: "Cleanup cancelled by user" } unless response == 'y'
      end
      
      # Calculate space to be freed
      space_freed = extracts_to_remove.sum { |path| calculate_directory_size(path) }
      
      # Remove extracts
      removed_count = 0
      extracts_to_remove.each do |extract_path|
        begin
          FileUtils.rm_rf(extract_path)
          removed_count += 1
          puts "Removed: #{File.basename(extract_path)}" if config.verbose
        rescue => e
          puts "Failed to remove #{File.basename(extract_path)}: #{e.message}" if config.verbose
        end
      end
      
      {
        success: true,
        removed_count: removed_count,
        space_freed: format_size(space_freed)
      }
    end

    # Validate an existing extract
    def validate_extract(extract_path)
      return { valid: false, error: "Extract directory not found" } unless Dir.exist?(extract_path)
      
      manifest_path = File.join(extract_path, 'manifest.json')
      return { valid: false, error: "Manifest file not found" } unless File.exist?(manifest_path)
      
      begin
        manifest = JSON.parse(File.read(manifest_path))
        
        # Validate manifest structure
        required_keys = %w[route_extract]
        missing_keys = required_keys - manifest.keys
        return { valid: false, error: "Invalid manifest: missing keys #{missing_keys.join(', ')}" } if missing_keys.any?
        
        # Validate files exist
        missing_files = []
        manifest['route_extract']['files']['list'].each do |file_path|
          full_path = File.join(extract_path, file_path)
          missing_files << file_path unless File.exist?(full_path)
        end
        
        if missing_files.any?
          return { 
            valid: false, 
            error: "Missing files: #{missing_files.join(', ')}" 
          }
        end
        
        {
          valid: true,
          manifest: manifest,
          files_count: manifest['route_extract']['files']['count'],
          route: manifest['route_extract']['route']
        }
        
      rescue JSON::ParserError => e
        { valid: false, error: "Invalid manifest JSON: #{e.message}" }
      end
    end

    # List all existing extracts
    def list_extracts
      extract_base = config.full_extract_path
      return [] unless Dir.exist?(extract_base)
      
      extracts = []
      
      Dir.glob(File.join(extract_base, '*')).select { |path| File.directory?(path) }.each do |extract_path|
        validation = validate_extract(extract_path)
        
        extract_info = {
          path: extract_path,
          name: File.basename(extract_path),
          size: format_size(calculate_directory_size(extract_path)),
          valid: validation[:valid]
        }
        
        if validation[:valid]
          extract_info.merge!(
            route: validation[:route],
            files_count: validation[:files_count],
            created_at: extract_timestamp_from_name(File.basename(extract_path))
          )
        else
          extract_info[:error] = validation[:error]
        end
        
        extracts << extract_info
      end
      
      extracts.sort_by { |extract| extract[:created_at] || DateTime.new(1970, 1, 1) }.reverse
    end

    private

    def validate_extraction_environment!
      unless config.rails_application?
        raise Error, "Not in a Rails application directory. Please run this command from a Rails application root."
      end
      
      # Ensure extract directory exists
      FileUtils.mkdir_p(config.full_extract_path)
    end

    def calculate_directory_size(directory)
      total_size = 0
      
      Find.find(directory) do |path|
        if File.file?(path)
          total_size += File.size(path)
        end
      end
      
      total_size
    end

    def format_size(bytes)
      units = %w[B KB MB GB TB]
      size = bytes.to_f
      unit_index = 0
      
      while size >= 1024 && unit_index < units.length - 1
        size /= 1024
        unit_index += 1
      end
      
      "#{size.round(2)} #{units[unit_index]}"
    end

    def parse_time_duration(duration_string)
      # Parse duration strings like "7d", "2w", "1m", "6h"
      match = duration_string.match(/^(\d+)([hdwm])$/)
      raise Error, "Invalid duration format: #{duration_string}" unless match
      
      amount = match[1].to_i
      unit = match[2]
      
      case unit
      when 'h'
        DateTime.now - (amount / 24.0)
      when 'd'
        DateTime.now - amount
      when 'w'
        DateTime.now - (amount * 7)
      when 'm'
        DateTime.now - (amount * 30)
      else
        raise Error, "Invalid duration unit: #{unit}"
      end
    end

    def extract_timestamp_from_name(name)
      if name.match(/_(\d{8}_\d{6})$/)
        DateTime.strptime($1, '%Y%m%d_%H%M%S')
      else
        nil
      end
    end
  end
end

