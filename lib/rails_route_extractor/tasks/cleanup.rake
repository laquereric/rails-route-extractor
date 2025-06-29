# frozen_string_literal: true

namespace :rails_route_extractor do
  desc "Clean up old extracts"
  task :cleanup, [:options] => :environment do |_t, args|
    require 'rails_route_extractor'

    puts "Cleaning up old extracts..."
    puts "=" * 40

    begin
      result = RailsRouteExtractor.cleanup_extracts

      if result[:success]
        puts "✅ Successfully cleaned up extracts"
        puts "🗑️  Removed extracts: #{result[:removed_count]}"
        puts "💾 Space freed: #{result[:space_freed]}"
      else
        puts "❌ Cleanup failed: #{result[:error]}"
        exit 1
      end
    rescue => e
      puts "❌ Error during cleanup: #{e.message}"
      exit 1
    end
  end

  desc "Show extraction statistics"
  task :stats => :environment do
    require 'rails_route_extractor'

    puts "Extraction Statistics"
    puts "=" * 30

    begin
      manager = RailsRouteExtractor::ExtractManager.new(RailsRouteExtractor.config)
      stats = manager.extract_stats

      puts "Total extracts: #{stats[:total_extracts]}"
      puts "Total size: #{stats[:total_size]}"
      puts "Oldest extract: #{stats[:oldest_extract]}"
      puts "Newest extract: #{stats[:newest_extract]}"

      if stats[:extract_details]&.any?
        puts "\nRecent extracts:"
        stats[:extract_details].first(5).each do |extract|
          puts "  - #{extract[:name]} (#{extract[:size]}) - #{extract[:created_at]}"
        end
      end
    rescue => e
      puts "❌ Error getting statistics: #{e.message}"
      exit 1
    end
  end

  desc "List all extracts"
  task :list_extracts => :environment do
    require 'rails_route_extractor'

    puts "Existing Extracts"
    puts "=" * 30

    begin
      manager = RailsRouteExtractor::ExtractManager.new(RailsRouteExtractor.config)
      extracts = manager.list_extracts

      if extracts.empty?
        puts "No extracts found."
        exit 0
      end

      puts sprintf("%-30s %-20s %-15s %-10s", "Name", "Route", "Files", "Size")
      puts "-" * 80

      extracts.each do |extract|
        name = extract[:name] || "N/A"
        route = extract[:route] ? "#{extract[:route][:controller]}##{extract[:route][:action]}" : "N/A"
        files = extract[:files_count] || "N/A"
        size = extract[:size] || "N/A"

        puts sprintf("%-30s %-20s %-15s %-10s", 
                    name[0..29], 
                    route[0..19], 
                    files, 
                    size)
      end

      puts "\nTotal: #{extracts.length} extracts"
    rescue => e
      puts "❌ Error listing extracts: #{e.message}"
      exit 1
    end
  end

  desc "Clean up extracts older than specified time"
  task :cleanup_old, [:older_than] => :environment do |_t, args|
    require 'rails_route_extractor'

    older_than = args[:older_than] || "7d"
    puts "Cleaning up extracts older than: #{older_than}"
    puts "=" * 50

    begin
      result = RailsRouteExtractor.cleanup_extracts(older_than: older_than)

      if result[:success]
        puts "✅ Successfully cleaned up old extracts"
        puts "🗑️  Removed extracts: #{result[:removed_count]}"
        puts "💾 Space freed: #{result[:space_freed]}"
      else
        puts "❌ Cleanup failed: #{result[:error]}"
        exit 1
      end
    rescue => e
      puts "❌ Error during cleanup: #{e.message}"
      exit 1
    end
  end

  desc "Force cleanup all extracts"
  task :cleanup_all => :environment do
    require 'rails_route_extractor'

    puts "⚠️  WARNING: This will remove ALL extracts!"
    puts "Are you sure? (y/N)"
    
    response = STDIN.gets.chomp.downcase
    unless response == 'y' || response == 'yes'
      puts "Cleanup cancelled."
      exit 0
    end

    puts "Cleaning up ALL extracts..."
    puts "=" * 30

    begin
      result = RailsRouteExtractor.cleanup_extracts(force: true)

      if result[:success]
        puts "✅ Successfully cleaned up all extracts"
        puts "🗑️  Removed extracts: #{result[:removed_count]}"
        puts "💾 Space freed: #{result[:space_freed]}"
      else
        puts "❌ Cleanup failed: #{result[:error]}"
        exit 1
      end
    rescue => e
      puts "❌ Error during cleanup: #{e.message}"
      exit 1
    end
  end

  desc "Validate extract integrity"
  task :validate_extracts => :environment do
    require 'rails_route_extractor'

    puts "Validating extract integrity..."
    puts "=" * 40

    begin
      manager = RailsRouteExtractor::ExtractManager.new(RailsRouteExtractor.config)
      extracts = manager.list_extracts

      if extracts.empty?
        puts "No extracts found to validate."
        exit 0
      end

      valid_count = 0
      invalid_count = 0

      extracts.each do |extract|
        if extract[:valid]
          valid_count += 1
          puts "✅ #{extract[:name]} - Valid"
        else
          invalid_count += 1
          puts "❌ #{extract[:name]} - Invalid (#{extract[:error]})"
        end
      end

      puts "\nValidation Summary:"
      puts "  Valid extracts: #{valid_count}"
      puts "  Invalid extracts: #{invalid_count}"
      puts "  Total extracts: #{extracts.length}"

      if invalid_count > 0
        puts "\nConsider running cleanup to remove invalid extracts."
        exit 1
      else
        puts "\n🎉 All extracts are valid!"
      end
    rescue => e
      puts "❌ Error validating extracts: #{e.message}"
      exit 1
    end
  end

  desc "Show disk usage for extracts"
  task :disk_usage => :environment do
    require 'rails_route_extractor'

    puts "Extract Disk Usage"
    puts "=" * 30

    begin
      manager = RailsRouteExtractor::ExtractManager.new(RailsRouteExtractor.config)
      usage = manager.disk_usage

      puts "Total size: #{usage[:total_size]}"
      puts "Extract count: #{usage[:extract_count]}"
      puts "Average size per extract: #{usage[:average_size]}"
      puts "Largest extract: #{usage[:largest_extract]}"
      puts "Smallest extract: #{usage[:smallest_extract]}"

      if usage[:size_distribution]&.any?
        puts "\nSize distribution:"
        usage[:size_distribution].each do |range, count|
          puts "  #{range}: #{count} extracts"
        end
      end
    rescue => e
      puts "❌ Error getting disk usage: #{e.message}"
      exit 1
    end
  end
end

