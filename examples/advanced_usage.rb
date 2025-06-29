#!/usr/bin/env ruby
# frozen_string_literal: true

# Advanced RouteExtract Usage Examples
# 
# This file demonstrates advanced usage patterns and integration scenarios
# for the RouteExtract gem.

require 'route_extract'

puts "RouteExtract Advanced Usage Examples"
puts "=" * 50

# Example 1: Custom Configuration for Different Environments
puts "\n1. Environment-Specific Configuration"
puts "-" * 40

class AdvancedConfiguration
  def self.setup_for_environment(env)
    RouteExtract.configure do |config|
      case env.to_s
      when 'development'
        config.verbose = true
        config.include_gems = true
        config.include_tests = true
        config.compress_extracts = false
        config.max_depth = 5
      when 'production'
        config.verbose = false
        config.include_gems = false
        config.include_tests = false
        config.compress_extracts = true
        config.max_depth = 3
      when 'testing'
        config.verbose = true
        config.include_gems = false
        config.include_tests = true
        config.compress_extracts = false
        config.max_depth = 4
      end
      
      # Common exclusions
      config.exclude_patterns += %w[
        vendor/cache
        tmp/
        log/
        public/assets
        node_modules
        *.backup
        *.tmp
      ]
    end
  end
end

# Setup for current environment
current_env = ENV['RAILS_ENV'] || 'development'
AdvancedConfiguration.setup_for_environment(current_env)
puts "✓ Configuration optimized for #{current_env} environment"

# Example 2: Batch Route Analysis
puts "\n2. Batch Route Analysis"
puts "-" * 40

class RouteAnalysisReport
  def initialize
    @analyzer = RouteExtract::RouteAnalyzer.new(RouteExtract.config)
    @gem_analyzer = RouteExtract::GemAnalyzer.new(RouteExtract.config)
  end
  
  def generate_comprehensive_report
    routes = RouteExtract.list_routes
    
    report = {
      summary: {
        total_routes: routes.length,
        controllers: routes.map { |r| r[:controller] }.uniq.length,
        actions: routes.map { |r| r[:action] }.uniq.length
      },
      complexity_analysis: analyze_route_complexity(routes.first(10)),
      dependency_analysis: analyze_dependencies(routes.first(5)),
      gem_usage: analyze_gem_usage
    }
    
    report
  end
  
  private
  
  def analyze_route_complexity(routes)
    complexity_data = {}
    
    routes.each do |route|
      pattern = "#{route[:controller]}##{route[:action]}"
      
      begin
        dependencies = @analyzer.route_dependencies(pattern)
        complexity_data[pattern] = {
          model_count: dependencies[:models]&.length || 0,
          view_count: dependencies[:views]&.length || 0,
          gem_count: dependencies[:gems]&.length || 0,
          total_dependencies: dependencies.values.flatten.length
        }
      rescue => e
        complexity_data[pattern] = { error: e.message }
      end
    end
    
    complexity_data
  end
  
  def analyze_dependencies(routes)
    all_dependencies = Hash.new { |h, k| h[k] = [] }
    
    routes.each do |route|
      pattern = "#{route[:controller]}##{route[:action]}"
      
      begin
        dependencies = @analyzer.route_dependencies(pattern)
        dependencies[:gems]&.each do |gem|
          all_dependencies[gem] << pattern
        end
      rescue => e
        puts "  ⚠ Error analyzing #{pattern}: #{e.message}"
      end
    end
    
    # Sort by frequency
    all_dependencies.sort_by { |_, routes| -routes.length }.to_h
  end
  
  def analyze_gem_usage
    begin
      gems_info = @gem_analyzer.analyze_bundle_gems
      
      {
        total_gems: gems_info.length,
        rails_gems: gems_info.select { |_, info| info[:name].include?('rails') }.length,
        large_gems: gems_info.select { |_, info| info[:size] > 1_000_000 }.length
      }
    rescue => e
      { error: e.message }
    end
  end
end

begin
  reporter = RouteAnalysisReport.new
  report = reporter.generate_comprehensive_report
  
  puts "Analysis Report:"
  puts "  Total routes: #{report[:summary][:total_routes]}"
  puts "  Controllers: #{report[:summary][:controllers]}"
  puts "  Actions: #{report[:summary][:actions]}"
  
  if report[:dependency_analysis].any?
    puts "\nMost common gem dependencies:"
    report[:dependency_analysis].first(3).each do |gem, routes|
      puts "  #{gem}: used by #{routes.length} routes"
    end
  end
  
  if report[:gem_usage][:total_gems]
    puts "\nGem usage summary:"
    puts "  Total gems: #{report[:gem_usage][:total_gems]}"
    puts "  Rails gems: #{report[:gem_usage][:rails_gems]}"
    puts "  Large gems: #{report[:gem_usage][:large_gems]}"
  end
rescue => e
  puts "⚠ Error generating analysis report: #{e.message}"
end

# Example 3: Custom Extraction Pipeline
puts "\n3. Custom Extraction Pipeline"
puts "-" * 40

class CustomExtractionPipeline
  def initialize
    @manager = RouteExtract::ExtractManager.new(RouteExtract.config)
    @file_analyzer = RouteExtract::FileAnalyzer.new(RouteExtract.config)
  end
  
  def extract_and_analyze(route_patterns, options = {})
    results = []
    
    route_patterns.each do |pattern|
      puts "Processing route: #{pattern}"
      
      # Extract the route
      extract_result = @manager.extract_route(pattern, options)
      
      if extract_result[:success]
        # Analyze the extracted files
        analysis = analyze_extracted_files(extract_result[:extract_path])
        
        results << {
          route: pattern,
          extraction: extract_result,
          analysis: analysis
        }
        
        puts "  ✓ Extracted and analyzed #{extract_result[:files_count]} files"
      else
        puts "  ✗ Failed to extract: #{extract_result[:error]}"
        results << {
          route: pattern,
          extraction: extract_result,
          analysis: nil
        }
      end
    end
    
    # Generate summary report
    generate_pipeline_report(results)
  end
  
  private
  
  def analyze_extracted_files(extract_path)
    ruby_files = Dir.glob(File.join(extract_path, '**', '*.rb'))
    return { error: 'No Ruby files found' } if ruby_files.empty?
    
    analysis = @file_analyzer.analyze_files(ruby_files)
    suggestions = @file_analyzer.suggest_optimizations(analysis)
    
    {
      file_count: analysis[:summary][:total_files],
      total_lines: analysis[:summary][:total_lines],
      complexity_distribution: analysis[:summary][:complexity_distribution],
      security_issues: suggestions[:security].length,
      performance_issues: suggestions[:performance].length,
      maintainability_issues: suggestions[:maintainability].length
    }
  end
  
  def generate_pipeline_report(results)
    successful = results.select { |r| r[:extraction][:success] }
    failed = results.select { |r| !r[:extraction][:success] }
    
    puts "\nPipeline Summary:"
    puts "  Successful extractions: #{successful.length}"
    puts "  Failed extractions: #{failed.length}"
    
    if successful.any?
      total_files = successful.sum { |r| r[:analysis][:file_count] }
      total_lines = successful.sum { |r| r[:analysis][:total_lines] }
      total_security_issues = successful.sum { |r| r[:analysis][:security_issues] }
      
      puts "  Total files analyzed: #{total_files}"
      puts "  Total lines of code: #{total_lines}"
      puts "  Security issues found: #{total_security_issues}"
    end
    
    if failed.any?
      puts "\nFailed extractions:"
      failed.each do |result|
        puts "  #{result[:route]}: #{result[:extraction][:error]}"
      end
    end
    
    results
  end
end

# Run custom pipeline
begin
  pipeline = CustomExtractionPipeline.new
  
  # Get some sample routes
  sample_routes = RouteExtract.list_routes.first(3).map { |r| "#{r[:controller]}##{r[:action]}" }
  
  if sample_routes.any?
    puts "Running custom extraction pipeline for: #{sample_routes.join(', ')}"
    results = pipeline.extract_and_analyze(sample_routes, mode: 'mvc')
  else
    puts "No routes available for pipeline demonstration"
  end
rescue => e
  puts "⚠ Error running custom pipeline: #{e.message}"
end

# Example 4: Integration with External Tools
puts "\n4. Integration with External Tools"
puts "-" * 40

class ExternalToolIntegration
  def self.export_to_json(extract_path, output_file)
    manifest_path = File.join(extract_path, 'manifest.json')
    return false unless File.exist?(manifest_path)
    
    manifest = JSON.parse(File.read(manifest_path))
    
    # Add file contents to export
    export_data = manifest.dup
    export_data['file_contents'] = {}
    
    manifest['route_extract']['files']['list'].each do |file_path|
      full_path = File.join(extract_path, file_path)
      if File.exist?(full_path) && File.readable?(full_path)
        export_data['file_contents'][file_path] = File.read(full_path)
      end
    end
    
    File.write(output_file, JSON.pretty_generate(export_data))
    true
  end
  
  def self.generate_documentation(extract_path, output_file)
    manifest_path = File.join(extract_path, 'manifest.json')
    return false unless File.exist?(manifest_path)
    
    manifest = JSON.parse(File.read(manifest_path))
    route_info = manifest['route_extract']['route']
    
    doc_content = <<~DOC
      # Route Documentation: #{route_info['controller']}##{route_info['action']}
      
      ## Route Information
      - **Pattern**: #{route_info['pattern']}
      - **HTTP Method**: #{route_info['method']}
      - **Controller**: #{route_info['controller']}
      - **Action**: #{route_info['action']}
      - **Helper**: #{route_info['helper'] || 'N/A'}
      
      ## Files Included
      #{manifest['route_extract']['files']['list'].map { |f| "- #{f}" }.join("\n")}
      
      ## Statistics
      - **Total Files**: #{manifest['route_extract']['files']['count']}
      - **Total Size**: #{manifest['route_extract']['statistics']['total_size']}
      - **Generated**: #{manifest['route_extract']['generated_at']}
      
      ## File Types
      #{manifest['route_extract']['statistics']['file_types'].map { |type, count| "- #{type}: #{count} files" }.join("\n")}
    DOC
    
    File.write(output_file, doc_content)
    true
  end
end

# Demonstrate external tool integration
begin
  # Get the most recent extract
  manager = RouteExtract::ExtractManager.new(RouteExtract.config)
  extracts = manager.list_extracts
  
  if extracts.any? && extracts.first[:valid]
    extract = extracts.first
    extract_path = extract[:path]
    
    # Export to JSON
    json_file = File.join(extract_path, 'export.json')
    if ExternalToolIntegration.export_to_json(extract_path, json_file)
      puts "✓ Exported extract to JSON: #{json_file}"
    end
    
    # Generate documentation
    doc_file = File.join(extract_path, 'README.md')
    if ExternalToolIntegration.generate_documentation(extract_path, doc_file)
      puts "✓ Generated documentation: #{doc_file}"
    end
  else
    puts "No valid extracts available for external tool integration demo"
  end
rescue => e
  puts "⚠ Error with external tool integration: #{e.message}"
end

# Example 5: Performance Monitoring
puts "\n5. Performance Monitoring"
puts "-" * 40

class PerformanceMonitor
  def self.benchmark_extraction(route_pattern, iterations = 3)
    require 'benchmark'
    
    times = []
    
    iterations.times do |i|
      puts "  Iteration #{i + 1}/#{iterations}"
      
      time = Benchmark.realtime do
        result = RouteExtract.extract_route(route_pattern, mode: 'mvc')
        unless result[:success]
          puts "    ⚠ Extraction failed: #{result[:error]}"
        end
      end
      
      times << time
    end
    
    {
      average_time: times.sum / times.length,
      min_time: times.min,
      max_time: times.max,
      iterations: iterations
    }
  end
end

# Run performance benchmark
begin
  sample_routes = RouteExtract.list_routes.first(2)
  
  if sample_routes.any?
    route_pattern = "#{sample_routes.first[:controller]}##{sample_routes.first[:action]}"
    puts "Benchmarking extraction for: #{route_pattern}"
    
    benchmark = PerformanceMonitor.benchmark_extraction(route_pattern, 2)
    
    puts "Performance Results:"
    puts "  Average time: #{benchmark[:average_time].round(3)}s"
    puts "  Min time: #{benchmark[:min_time].round(3)}s"
    puts "  Max time: #{benchmark[:max_time].round(3)}s"
  else
    puts "No routes available for performance benchmarking"
  end
rescue => e
  puts "⚠ Error during performance monitoring: #{e.message}"
end

puts "\n" + "=" * 50
puts "Advanced examples completed!"
puts "\nThese examples demonstrate:"
puts "1. Environment-specific configuration"
puts "2. Comprehensive route analysis and reporting"
puts "3. Custom extraction pipelines with analysis"
puts "4. Integration with external tools and documentation"
puts "5. Performance monitoring and benchmarking"
puts "\nUse these patterns as starting points for your own advanced integrations!"

