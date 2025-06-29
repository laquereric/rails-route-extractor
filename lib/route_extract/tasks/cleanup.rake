# frozen_string_literal: true

namespace :route_extract do
  desc "Clean up old extracts"
  task :cleanup => :environment do
    require 'route_extract'
    
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end
    
    options = {}
    options[:older_than] = ENV['OLDER_THAN'] if ENV['OLDER_THAN']
    options[:keep_latest] = ENV['KEEP_LATEST'].to_i if ENV['KEEP_LATEST']
    options[:force] = ENV['FORCE'] == 'true'
    
    begin
      result = RouteExtract.cleanup_extracts(options)
      
      if result[:success]
        puts "✓ Cleaned up #{result[:removed_count]} extract directories"
        puts "  Space freed: #{result[:space_freed]}"
      else
        puts "✗ Cleanup failed: #{result[:error]}"
        exit 1
      end
      
    rescue => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.join("\n") if RouteExtract.config.verbose
      exit 1
    end
  end

  desc "Clean up extracts older than specified time"
  task :cleanup_old, [:duration] => :environment do |t, args|
    require 'route_extract'
    
    duration = args[:duration] || ENV['OLDER_THAN']
    
    unless duration
      puts "Usage: rake route_extract:cleanup_old[duration]"
      puts "Examples:"
      puts "  rake route_extract:cleanup_old[7d]   # Remove extracts older than 7 days"
      puts "  rake route_extract:cleanup_old[2w]   # Remove extracts older than 2 weeks"
      puts "  rake route_extract:cleanup_old[1m]   # Remove extracts older than 1 month"
      puts "  rake route_extract:cleanup_old[6h]   # Remove extracts older than 6 hours"
      exit 1
    end
    
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end
    
    options = {
      older_than: duration,
      force: ENV['FORCE'] == 'true'
    }
    
    begin
      result = RouteExtract.cleanup_extracts(options)
      
      if result[:success]
        puts "✓ Cleaned up #{result[:removed_count]} extract directories older than #{duration}"
        puts "  Space freed: #{result[:space_freed]}"
      else
        puts "✗ Cleanup failed: #{result[:error]}"
        exit 1
      end
      
    rescue => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.join("\n") if RouteExtract.config.verbose
      exit 1
    end
  end

  desc "Keep only the N most recent extracts"
  task :cleanup_keep, [:count] => :environment do |t, args|
    require 'route_extract'
    
    count = args[:count]&.to_i || ENV['KEEP_LATEST']&.to_i
    
    unless count && count > 0
      puts "Usage: rake route_extract:cleanup_keep[count]"
      puts "Examples:"
      puts "  rake route_extract:cleanup_keep[5]   # Keep only the 5 most recent extracts"
      puts "  rake route_extract:cleanup_keep[10]  # Keep only the 10 most recent extracts"
      exit 1
    end
    
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end
    
    options = {
      keep_latest: count,
      force: ENV['FORCE'] == 'true'
    }
    
    begin
      result = RouteExtract.cleanup_extracts(options)
      
      if result[:success]
        puts "✓ Cleaned up #{result[:removed_count]} extract directories (kept #{count} most recent)"
        puts "  Space freed: #{result[:space_freed]}"
      else
        puts "✗ Cleanup failed: #{result[:error]}"
        exit 1
      end
      
    rescue => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.join("\n") if RouteExtract.config.verbose
      exit 1
    end
  end

  desc "Remove all extracts (use with caution)"
  task :cleanup_all => :environment do
    require 'route_extract'
    
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end
    
    force = ENV['FORCE'] == 'true'
    
    unless force
      puts "This will remove ALL extract directories."
      print "Are you sure? Type 'yes' to confirm: "
      response = STDIN.gets.chomp
      unless response.downcase == 'yes'
        puts "Cleanup cancelled."
        exit 0
      end
    end
    
    options = { force: true }
    
    begin
      result = RouteExtract.cleanup_extracts(options)
      
      if result[:success]
        puts "✓ Removed all #{result[:removed_count]} extract directories"
        puts "  Space freed: #{result[:space_freed]}"
      else
        puts "✗ Cleanup failed: #{result[:error]}"
        exit 1
      end
      
    rescue => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.join("\n") if RouteExtract.config.verbose
      exit 1
    end
  end

  desc "Validate existing extracts"
  task :validate_extracts => :environment do
    require 'route_extract'
    
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end
    
    begin
      manager = RouteExtract::ExtractManager.new(RouteExtract.config)
      extracts = manager.list_extracts
      
      if extracts.empty?
        puts "No extracts found to validate."
        return
      end
      
      valid_count = 0
      invalid_count = 0
      
      puts "Validating #{extracts.length} extracts..."
      puts "-" * 60
      
      extracts.each do |extract|
        if extract[:valid]
          puts "✓ #{extract[:name]}"
          valid_count += 1
        else
          puts "✗ #{extract[:name]}: #{extract[:error]}"
          invalid_count += 1
        end
      end
      
      puts "-" * 60
      puts "Validation Summary:"
      puts "  Valid extracts: #{valid_count}"
      puts "  Invalid extracts: #{invalid_count}"
      puts "  Total extracts: #{extracts.length}"
      
      if invalid_count > 0
        puts "\nTo remove invalid extracts, run:"
        puts "  rake route_extract:cleanup_invalid FORCE=true"
      end
      
    rescue => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.join("\n") if RouteExtract.config.verbose
      exit 1
    end
  end

  desc "Remove invalid extracts"
  task :cleanup_invalid => :environment do
    require 'route_extract'
    
    RouteExtract.configure do |config|
      config.verbose = ENV['VERBOSE'] == 'true'
    end
    
    force = ENV['FORCE'] == 'true'
    
    begin
      manager = RouteExtract::ExtractManager.new(RouteExtract.config)
      extracts = manager.list_extracts
      
      invalid_extracts = extracts.reject { |extract| extract[:valid] }
      
      if invalid_extracts.empty?
        puts "No invalid extracts found."
        return
      end
      
      unless force
        puts "The following invalid extracts will be removed:"
        invalid_extracts.each { |extract| puts "  #{extract[:name]}: #{extract[:error]}" }
        print "Continue? (y/N): "
        response = STDIN.gets.chomp.downcase
        unless response == 'y'
          puts "Cleanup cancelled."
          exit 0
        end
      end
      
      removed_count = 0
      space_freed = 0
      
      invalid_extracts.each do |extract|
        begin
          size = File.directory?(extract[:path]) ? calculate_directory_size(extract[:path]) : 0
          FileUtils.rm_rf(extract[:path])
          removed_count += 1
          space_freed += size
          puts "Removed: #{extract[:name]}" if RouteExtract.config.verbose
        rescue => e
          puts "Failed to remove #{extract[:name]}: #{e.message}" if RouteExtract.config.verbose
        end
      end
      
      puts "✓ Removed #{removed_count} invalid extract directories"
      puts "  Space freed: #{format_size(space_freed)}"
      
    rescue => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.join("\n") if RouteExtract.config.verbose
      exit 1
    end
  end

  desc "Show cleanup help"
  task :cleanup_help do
    puts "RouteExtract Cleanup Tasks:"
    puts ""
    puts "Basic cleanup:"
    puts "  rake route_extract:cleanup                    # Interactive cleanup"
    puts "  rake route_extract:cleanup_old[7d]            # Remove extracts older than 7 days"
    puts "  rake route_extract:cleanup_keep[5]            # Keep only 5 most recent extracts"
    puts "  rake route_extract:cleanup_all                # Remove all extracts (dangerous!)"
    puts ""
    puts "Validation and repair:"
    puts "  rake route_extract:validate_extracts          # Validate all existing extracts"
    puts "  rake route_extract:cleanup_invalid            # Remove invalid extracts"
    puts ""
    puts "Environment variables:"
    puts "  FORCE=true                                    # Skip confirmation prompts"
    puts "  VERBOSE=true                                  # Enable verbose output"
    puts "  OLDER_THAN=7d                                 # Duration for cleanup_old"
    puts "  KEEP_LATEST=5                                 # Count for cleanup_keep"
    puts ""
    puts "Duration formats:"
    puts "  h = hours    (e.g., 6h = 6 hours)"
    puts "  d = days     (e.g., 7d = 7 days)"
    puts "  w = weeks    (e.g., 2w = 2 weeks)"
    puts "  m = months   (e.g., 1m = 1 month)"
    puts ""
    puts "Examples:"
    puts "  rake route_extract:cleanup_old[7d] FORCE=true"
    puts "  rake route_extract:cleanup_keep[10] VERBOSE=true"
    puts "  rake route_extract:validate_extracts"
  end

  # Helper methods
  private

  def calculate_directory_size(directory)
    total_size = 0
    
    Find.find(directory) do |path|
      if File.file?(path)
        total_size += File.size(path)
      end
    end
    
    total_size
  rescue
    0
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
end

