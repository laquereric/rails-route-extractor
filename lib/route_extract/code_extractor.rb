# frozen_string_literal: true

require 'fileutils'
require 'json'

module RouteExtract
  class CodeExtractor
    attr_reader :config, :route_analyzer

    def initialize(config)
      @config = config
      @route_analyzer = RouteAnalyzer.new(config)
    end

    # Extract code for a single route
    def extract_route(route_pattern, options = {})
      route_info = route_analyzer.route_info(route_pattern)
      
      unless route_info
        return {
          success: false,
          error: "Route not found: #{route_pattern}"
        }
      end

      extract_path = create_extract_directory(route_info, options)
      
      begin
        extracted_files = []
        total_size = 0
        
        # Extract based on configuration and options
        mode = options[:mode] || 'mvc'
        apply_extraction_mode(mode)
        
        # Extract models
        if config.include_models
          model_files = extract_models(route_info, extract_path)
          extracted_files.concat(model_files[:files])
          total_size += model_files[:size]
        end
        
        # Extract views
        if config.include_views
          view_files = extract_views(route_info, extract_path)
          extracted_files.concat(view_files[:files])
          total_size += view_files[:size]
        end
        
        # Extract controllers
        if config.include_controllers
          controller_files = extract_controllers(route_info, extract_path)
          extracted_files.concat(controller_files[:files])
          total_size += controller_files[:size]
        end
        
        # Extract dependencies if enabled
        if config.include_gems
          dependency_files = extract_dependencies(route_info, extract_path)
          extracted_files.concat(dependency_files[:files])
          total_size += dependency_files[:size]
        end
        
        # Extract tests if enabled
        if config.include_tests
          test_files = extract_tests(route_info, extract_path)
          extracted_files.concat(test_files[:files])
          total_size += test_files[:size]
        end
        
        # Generate manifest
        manifest = generate_manifest(route_info, extracted_files, options)
        manifest_path = File.join(extract_path, "manifest.json")
        File.write(manifest_path, JSON.pretty_generate(manifest))
        
        # Compress if requested
        if options[:compress] || config.compress_extracts
          archive_path = compress_extract(extract_path)
          FileUtils.rm_rf(extract_path)
          extract_path = archive_path
        end
        
        {
          success: true,
          extract_path: extract_path,
          files_count: extracted_files.length,
          total_size: format_size(total_size),
          manifest: manifest
        }
        
      rescue => e
        # Clean up on error
        FileUtils.rm_rf(extract_path) if File.exist?(extract_path)
        
        {
          success: false,
          error: e.message,
          backtrace: config.verbose ? e.backtrace : nil
        }
      end
    end

    # Extract code for multiple routes
    def extract_routes(route_patterns, options = {})
      results = []
      successful_count = 0
      failed_count = 0
      total_files = 0
      total_size = 0
      
      route_patterns.each do |pattern|
        result = extract_route(pattern, options)
        results << result.merge(route_pattern: pattern)
        
        if result[:success]
          successful_count += 1
          total_files += result[:files_count]
          # Parse size back to bytes for summing
          total_size += parse_size(result[:total_size])
        else
          failed_count += 1
        end
      end
      
      {
        success: failed_count == 0,
        results: results,
        successful_count: successful_count,
        failed_count: failed_count,
        total_files: total_files,
        total_size: format_size(total_size)
      }
    end

    private

    def apply_extraction_mode(mode)
      case mode.to_s.downcase
      when 'm', 'models'
        config.models_only
      when 'v', 'views'
        config.views_only
      when 'c', 'controllers'
        config.controllers_only
      when 'mv', 'models_views'
        config.mv_mode
      when 'mc', 'models_controllers'
        config.mc_mode
      when 'vc', 'views_controllers'
        config.vc_mode
      when 'mvc', 'all'
        config.mvc_mode
      else
        raise Error, "Invalid extraction mode: #{mode}. Valid modes: m, v, c, mv, mc, vc, mvc"
      end
    end

    def create_extract_directory(route_info, options = {})
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      route_name = "#{route_info[:controller]}_#{route_info[:action]}"
      dir_name = "#{route_name}_#{timestamp}"
      
      base_path = options[:output] || config.full_extract_path
      extract_path = File.join(base_path, dir_name)
      
      FileUtils.mkdir_p(extract_path)
      
      # Create subdirectories
      %w[models views controllers gems tests].each do |subdir|
        FileUtils.mkdir_p(File.join(extract_path, subdir))
      end
      
      extract_path
    end

    def extract_models(route_info, extract_path)
      files = []
      total_size = 0
      models_dir = File.join(extract_path, "models")
      
      route_info[:files][:models].each do |model_file|
        next unless File.exist?(model_file)
        
        relative_path = model_file.sub(File.join(config.rails_root, "app", "models"), "")
        relative_path = relative_path.sub(/^\//, "")
        
        target_path = File.join(models_dir, relative_path)
        FileUtils.mkdir_p(File.dirname(target_path))
        
        FileUtils.cp(model_file, target_path)
        files << target_path
        total_size += File.size(model_file)
        
        puts "Extracted model: #{relative_path}" if config.verbose
      end
      
      # Extract model concerns if enabled
      if config.include_concerns
        concern_files = extract_model_concerns(route_info, models_dir)
        files.concat(concern_files[:files])
        total_size += concern_files[:size]
      end
      
      { files: files, size: total_size }
    end

    def extract_views(route_info, extract_path)
      files = []
      total_size = 0
      views_dir = File.join(extract_path, "views")
      
      route_info[:files][:views].each do |view_file|
        next unless File.exist?(view_file)
        
        relative_path = view_file.sub(File.join(config.rails_root, "app", "views"), "")
        relative_path = relative_path.sub(/^\//, "")
        
        target_path = File.join(views_dir, relative_path)
        FileUtils.mkdir_p(File.dirname(target_path))
        
        FileUtils.cp(view_file, target_path)
        files << target_path
        total_size += File.size(view_file)
        
        puts "Extracted view: #{relative_path}" if config.verbose
      end
      
      # Extract partials if enabled
      if config.include_partials
        partial_files = extract_partials(route_info, views_dir)
        files.concat(partial_files[:files])
        total_size += partial_files[:size]
      end
      
      # Extract helpers if enabled
      if config.include_helpers
        helper_files = extract_helpers(route_info, views_dir)
        files.concat(helper_files[:files])
        total_size += helper_files[:size]
      end
      
      { files: files, size: total_size }
    end

    def extract_controllers(route_info, extract_path)
      files = []
      total_size = 0
      controllers_dir = File.join(extract_path, "controllers")
      
      route_info[:files][:controllers].each do |controller_file|
        next unless File.exist?(controller_file)
        
        relative_path = controller_file.sub(File.join(config.rails_root, "app", "controllers"), "")
        relative_path = relative_path.sub(/^\//, "")
        
        target_path = File.join(controllers_dir, relative_path)
        FileUtils.mkdir_p(File.dirname(target_path))
        
        FileUtils.cp(controller_file, target_path)
        files << target_path
        total_size += File.size(controller_file)
        
        puts "Extracted controller: #{relative_path}" if config.verbose
      end
      
      # Extract controller concerns if enabled
      if config.include_concerns
        concern_files = extract_controller_concerns(route_info, controllers_dir)
        files.concat(concern_files[:files])
        total_size += concern_files[:size]
      end
      
      { files: files, size: total_size }
    end

    def extract_dependencies(route_info, extract_path)
      files = []
      total_size = 0
      gems_dir = File.join(extract_path, "gems")
      
      dependencies = route_analyzer.route_dependencies(route_info[:pattern])
      
      dependencies[:gems].each do |gem_name|
        gem_files = extract_gem_files(gem_name, gems_dir)
        files.concat(gem_files[:files])
        total_size += gem_files[:size]
      end
      
      { files: files, size: total_size }
    end

    def extract_tests(route_info, extract_path)
      files = []
      total_size = 0
      tests_dir = File.join(extract_path, "tests")
      
      # Look for RSpec tests
      controller_name = route_info[:controller]
      action_name = route_info[:action]
      
      # Controller specs
      controller_spec = File.join(config.rails_root, "spec", "controllers", "#{controller_name}_controller_spec.rb")
      if File.exist?(controller_spec)
        target_path = File.join(tests_dir, "spec", "controllers", "#{controller_name}_controller_spec.rb")
        FileUtils.mkdir_p(File.dirname(target_path))
        FileUtils.cp(controller_spec, target_path)
        files << target_path
        total_size += File.size(controller_spec)
      end
      
      # Feature specs
      feature_spec = File.join(config.rails_root, "spec", "features", "#{controller_name}_#{action_name}_spec.rb")
      if File.exist?(feature_spec)
        target_path = File.join(tests_dir, "spec", "features", "#{controller_name}_#{action_name}_spec.rb")
        FileUtils.mkdir_p(File.dirname(target_path))
        FileUtils.cp(feature_spec, target_path)
        files << target_path
        total_size += File.size(feature_spec)
      end
      
      { files: files, size: total_size }
    end

    def extract_model_concerns(route_info, models_dir)
      files = []
      total_size = 0
      
      route_info[:files][:concerns].each do |concern_file|
        next unless File.exist?(concern_file)
        next unless concern_file.include?("models/concerns")
        
        relative_path = concern_file.sub(File.join(config.rails_root, "app", "models"), "")
        relative_path = relative_path.sub(/^\//, "")
        
        target_path = File.join(models_dir, relative_path)
        FileUtils.mkdir_p(File.dirname(target_path))
        
        FileUtils.cp(concern_file, target_path)
        files << target_path
        total_size += File.size(concern_file)
        
        puts "Extracted model concern: #{relative_path}" if config.verbose
      end
      
      { files: files, size: total_size }
    end

    def extract_controller_concerns(route_info, controllers_dir)
      files = []
      total_size = 0
      
      route_info[:files][:concerns].each do |concern_file|
        next unless File.exist?(concern_file)
        next unless concern_file.include?("controllers/concerns")
        
        relative_path = concern_file.sub(File.join(config.rails_root, "app", "controllers"), "")
        relative_path = relative_path.sub(/^\//, "")
        
        target_path = File.join(controllers_dir, relative_path)
        FileUtils.mkdir_p(File.dirname(target_path))
        
        FileUtils.cp(concern_file, target_path)
        files << target_path
        total_size += File.size(concern_file)
        
        puts "Extracted controller concern: #{relative_path}" if config.verbose
      end
      
      { files: files, size: total_size }
    end

    def extract_partials(route_info, views_dir)
      files = []
      total_size = 0
      
      dependencies = route_analyzer.route_dependencies(route_info[:pattern])
      
      dependencies[:partials].each do |partial_file|
        next unless File.exist?(partial_file)
        
        relative_path = partial_file.sub(File.join(config.rails_root, "app", "views"), "")
        relative_path = relative_path.sub(/^\//, "")
        
        target_path = File.join(views_dir, relative_path)
        FileUtils.mkdir_p(File.dirname(target_path))
        
        FileUtils.cp(partial_file, target_path)
        files << target_path
        total_size += File.size(partial_file)
        
        puts "Extracted partial: #{relative_path}" if config.verbose
      end
      
      { files: files, size: total_size }
    end

    def extract_helpers(route_info, views_dir)
      files = []
      total_size = 0
      helpers_dir = File.join(views_dir, "helpers")
      
      route_info[:files][:helpers].each do |helper_file|
        next unless File.exist?(helper_file)
        
        relative_path = helper_file.sub(File.join(config.rails_root, "app", "helpers"), "")
        relative_path = relative_path.sub(/^\//, "")
        
        target_path = File.join(helpers_dir, relative_path)
        FileUtils.mkdir_p(File.dirname(target_path))
        
        FileUtils.cp(helper_file, target_path)
        files << target_path
        total_size += File.size(helper_file)
        
        puts "Extracted helper: #{relative_path}" if config.verbose
      end
      
      { files: files, size: total_size }
    end

    def extract_gem_files(gem_name, gems_dir)
      files = []
      total_size = 0
      
      begin
        gem_spec = Gem::Specification.find_by_name(gem_name)
        gem_path = gem_spec.gem_dir
        
        # Create gem directory
        gem_target_dir = File.join(gems_dir, gem_name)
        FileUtils.mkdir_p(gem_target_dir)
        
        # Copy essential gem files
        essential_files = %w[lib README.md LICENSE.txt CHANGELOG.md]
        essential_files.each do |file_pattern|
          Dir.glob(File.join(gem_path, file_pattern)).each do |file|
            next unless File.file?(file)
            
            relative_path = file.sub(gem_path, "")
            relative_path = relative_path.sub(/^\//, "")
            
            target_path = File.join(gem_target_dir, relative_path)
            FileUtils.mkdir_p(File.dirname(target_path))
            
            if File.directory?(file)
              FileUtils.cp_r(file, target_path)
            else
              FileUtils.cp(file, target_path)
            end
            
            files << target_path
            total_size += File.size(file) if File.file?(file)
          end
        end
        
        puts "Extracted gem: #{gem_name}" if config.verbose
        
      rescue Gem::LoadError
        puts "Warning: Gem not found: #{gem_name}" if config.verbose
      end
      
      { files: files, size: total_size }
    end

    def generate_manifest(route_info, extracted_files, options = {})
      {
        route_extract: {
          version: RouteExtract::VERSION,
          generated_at: Time.now.iso8601,
          route: {
            pattern: route_info[:pattern],
            controller: route_info[:controller],
            action: route_info[:action],
            method: route_info[:method],
            name: route_info[:name],
            helper: route_info[:helper]
          },
          extraction: {
            mode: options[:mode] || 'mvc',
            include_models: config.include_models,
            include_views: config.include_views,
            include_controllers: config.include_controllers,
            include_gems: config.include_gems,
            include_tests: config.include_tests
          },
          files: {
            count: extracted_files.length,
            list: extracted_files.map { |f| f.sub(config.full_extract_path, '') }
          },
          statistics: {
            total_size: format_size(extracted_files.sum { |f| File.exist?(f) ? File.size(f) : 0 }),
            file_types: count_file_types(extracted_files)
          }
        }
      }
    end

    def compress_extract(extract_path)
      archive_path = "#{extract_path}.tar.gz"
      
      Dir.chdir(File.dirname(extract_path)) do
        system("tar -czf #{File.basename(archive_path)} #{File.basename(extract_path)}")
      end
      
      archive_path
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

    def parse_size(size_string)
      # Parse size string back to bytes (rough approximation)
      value, unit = size_string.split(' ')
      value = value.to_f
      
      case unit
      when 'KB'
        (value * 1024).to_i
      when 'MB'
        (value * 1024 * 1024).to_i
      when 'GB'
        (value * 1024 * 1024 * 1024).to_i
      else
        value.to_i
      end
    end

    def count_file_types(files)
      types = Hash.new(0)
      
      files.each do |file|
        ext = File.extname(file).downcase
        ext = ext.empty? ? 'no_extension' : ext[1..-1]
        types[ext] += 1
      end
      
      types
    end
  end
end

