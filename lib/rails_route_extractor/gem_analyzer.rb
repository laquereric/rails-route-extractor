# frozen_string_literal: true

require 'bundler'

module RailsRouteExtractor
  class GemAnalyzer
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def analyze_gems
    end

    def find_gem_source(gem_name)
    end

    def get_gem_metadata(gem_name)
    end

    def analyze_gem_dependencies(gem_name)
    end

    # Analyze all gems in the current bundle
    def analyze_bundle_gems
      return {} unless defined?(Bundler)

      gems_info = {}
      
      Bundler.load.specs.each do |spec|
        gems_info[spec.name] = analyze_gem_spec(spec)
      end
      
      gems_info
    end

    # Analyze a specific gem
    def analyze_gem(gem_name)
      begin
        spec = Gem::Specification.find_by_name(gem_name)
        analyze_gem_spec(spec)
      rescue Gem::LoadError
        {
          name: gem_name,
          found: false,
          error: "Gem not found"
        }
      end
    end

    # Get gem dependencies for a list of files
    def extract_gem_dependencies(file_paths)
      gem_usage = Hash.new { |h, k| h[k] = [] }
      
      file_paths.each do |file_path|
        next unless File.exist?(file_path)
        
        content = File.read(file_path)
        detected_gems = detect_gem_usage(content, file_path)
        
        detected_gems.each do |gem_name|
          gem_usage[gem_name] << file_path
        end
      end
      
      # Convert to regular hash and get gem info
      result = {}
      gem_usage.each do |gem_name, files|
        result[gem_name] = {
          files_using: files.uniq,
          gem_info: analyze_gem(gem_name)
        }
      end
      
      result
    end

    # Extract essential files from a gem for inclusion in extract
    def extract_gem_files(gem_name, target_directory)
      gem_info = analyze_gem(gem_name)
      
      return { success: false, error: gem_info[:error] } unless gem_info[:found]
      
      extracted_files = []
      total_size = 0
      
      gem_dir = gem_info[:gem_dir]
      gem_target_dir = File.join(target_directory, gem_name)
      
      FileUtils.mkdir_p(gem_target_dir)
      
      # Extract lib directory (core functionality)
      lib_source = File.join(gem_dir, 'lib')
      if Dir.exist?(lib_source)
        lib_target = File.join(gem_target_dir, 'lib')
        copy_directory_selectively(lib_source, lib_target, gem_info[:important_files])
        extracted_files.concat(Dir.glob(File.join(lib_target, '**', '*')).select { |f| File.file?(f) })
      end
      
      # Extract essential documentation and configuration files
      essential_patterns = %w[
        README* LICENSE* CHANGELOG* HISTORY* CONTRIBUTING*
        *.gemspec Gemfile* Rakefile
        VERSION COPYING AUTHORS
      ]
      
      essential_patterns.each do |pattern|
        Dir.glob(File.join(gem_dir, pattern)).each do |file|
          next unless File.file?(file)
          
          relative_path = file.sub(gem_dir + '/', '')
          target_path = File.join(gem_target_dir, relative_path)
          
          FileUtils.mkdir_p(File.dirname(target_path))
          FileUtils.cp(file, target_path)
          extracted_files << target_path
        end
      end
      
      # Calculate total size
      total_size = extracted_files.sum { |f| File.exist?(f) ? File.size(f) : 0 }
      
      {
        success: true,
        gem_name: gem_name,
        version: gem_info[:version],
        extracted_files: extracted_files,
        total_size: total_size,
        target_directory: gem_target_dir
      }
    end

    # Create a dependency graph of gems
    def create_gem_dependency_graph
      return {} unless defined?(Bundler)

      graph = {}
      
      Bundler.load.specs.each do |spec|
        dependencies = spec.dependencies.select { |dep| dep.type == :runtime }
        
        graph[spec.name] = {
          version: spec.version.to_s,
          dependencies: dependencies.map(&:name),
          dependents: []
        }
      end
      
      # Build reverse dependencies
      graph.each do |gem_name, info|
        info[:dependencies].each do |dep_name|
          if graph[dep_name]
            graph[dep_name][:dependents] << gem_name
          end
        end
      end
      
      graph
    end

    # Find gems that are likely to be used by specific file types
    def suggest_gems_for_files(file_paths)
      suggestions = Hash.new { |h, k| h[k] = [] }
      
      file_paths.each do |file_path|
        next unless File.exist?(file_path)
        
        file_type = determine_file_type(file_path)
        content = File.read(file_path)
        
        case file_type
        when :controller
          suggestions[:authentication] << 'devise' if content.match?(/authenticate_user|current_user/)
          suggestions[:authorization] << 'cancancan' if content.match?(/can\?|cannot\?|authorize!/)
          suggestions[:pagination] << 'kaminari' if content.match?(/paginate|page\(/)
          suggestions[:search] << 'ransack' if content.match?(/ransack|search\(/)
        when :model
          suggestions[:file_upload] << 'paperclip' if content.match?(/has_attached_file/)
          suggestions[:file_upload] << 'carrierwave' if content.match?(/mount_uploader/)
          suggestions[:state_machine] << 'aasm' if content.match?(/aasm|state/)
          suggestions[:soft_delete] << 'paranoia' if content.match?(/acts_as_paranoid/)
        when :view
          suggestions[:ui] << 'bootstrap' if content.match?(/bootstrap|btn-|col-/)
          suggestions[:forms] << 'simple_form' if content.match?(/simple_form_for/)
          suggestions[:icons] << 'font-awesome' if content.match?(/fa-|fas |far /)
        end
      end
      
      suggestions
    end

    private

    def analyze_gem_spec(spec)
      {
        name: spec.name,
        version: spec.version.to_s,
        found: true,
        gem_dir: spec.gem_dir,
        summary: spec.summary,
        description: spec.description,
        homepage: spec.homepage,
        authors: spec.authors,
        license: spec.license,
        dependencies: spec.dependencies.map { |dep| { name: dep.name, type: dep.type, requirement: dep.requirement.to_s } },
        files: spec.files,
        lib_files: find_lib_files(spec),
        important_files: identify_important_files(spec),
        size: calculate_gem_size(spec.gem_dir)
      }
    end

    def find_lib_files(spec)
      lib_files = []
      lib_path = File.join(spec.gem_dir, 'lib')
      
      return lib_files unless Dir.exist?(lib_path)
      
      Dir.glob(File.join(lib_path, '**', '*.rb')).each do |file|
        relative_path = file.sub(spec.gem_dir + '/', '')
        lib_files << relative_path
      end
      
      lib_files.sort
    end

    def identify_important_files(spec)
      important = []
      
      # Main entry point
      main_file = File.join(spec.gem_dir, 'lib', "#{spec.name}.rb")
      important << "lib/#{spec.name}.rb" if File.exist?(main_file)
      
      # Rails-specific files
      if spec.name.include?('rails') || spec.dependencies.any? { |dep| dep.name == 'rails' }
        railtie_pattern = File.join(spec.gem_dir, 'lib', '**', '*railtie*.rb')
        Dir.glob(railtie_pattern).each do |file|
          relative_path = file.sub(spec.gem_dir + '/', '')
          important << relative_path
        end
        
        engine_pattern = File.join(spec.gem_dir, 'lib', '**', '*engine*.rb')
        Dir.glob(engine_pattern).each do |file|
          relative_path = file.sub(spec.gem_dir + '/', '')
          important << relative_path
        end
      end
      
      # Configuration files
      config_pattern = File.join(spec.gem_dir, 'lib', '**', '*config*.rb')
      Dir.glob(config_pattern).each do |file|
        relative_path = file.sub(gem_dir + '/', '')
        important << relative_path
      end
      
      important.uniq
    end

    def calculate_gem_size(gem_dir)
      total_size = 0
      
      Find.find(gem_dir) do |path|
        if File.file?(path)
          total_size += File.size(path)
        end
      end
      
      total_size
    rescue
      0
    end

    def detect_gem_usage(content, file_path)
      detected_gems = []
      
      # Direct require statements
      content.scan(/require\s+['"]([^'"\/]+)['"]/) do |match|
        gem_name = match[0]
        # Skip standard library and relative requires
        next if gem_name.start_with?('.') || standard_library?(gem_name)
        detected_gems << gem_name
      end
      
      # Gem-specific patterns
      gem_patterns = {
        'devise' => /devise|authenticate_user|current_user|user_signed_in\?/,
        'kaminari' => /paginate|page\(|per\(/,
        'cancancan' => /can\?|cannot\?|authorize!|load_and_authorize_resource/,
        'paperclip' => /has_attached_file|attachment/,
        'carrierwave' => /mount_uploader/,
        'sidekiq' => /perform_async|Sidekiq|include Sidekiq::Worker/,
        'resque' => /Resque/,
        'redis' => /Redis\.new|Redis\.current/,
        'elasticsearch' => /Elasticsearch|__elasticsearch__/,
        'ransack' => /ransack|search\(/,
        'simple_form' => /simple_form_for/,
        'bootstrap' => /bootstrap|btn-|col-/,
        'jquery' => /\$\(|jQuery/,
        'turbo' => /turbo|Turbo/,
        'stimulus' => /stimulus|Stimulus/,
        'image_processing' => /image_processing|ImageProcessing/,
        'mini_magick' => /MiniMagick/,
        'rmagick' => /RMagick|Magick/
      }
      
      gem_patterns.each do |gem_name, pattern|
        if content.match?(pattern)
          detected_gems << gem_name
        end
      end
      
      detected_gems.uniq
    end

    def standard_library?(name)
      # Common Ruby standard library modules
      stdlib_modules = %w[
        json yaml csv uri net/http openssl digest base64 time date
        fileutils pathname tempfile logger ostruct set forwardable
        singleton observer delegate benchmark timeout mutex thread
        fiber continuation enumerator rational complex bigdecimal
        stringio strscan scanf zlib gzip
      ]
      
      stdlib_modules.include?(name)
    end

    def determine_file_type(file_path)
      case file_path
      when /controllers/
        :controller
      when /models/
        :model
      when /views/
        :view
      when /helpers/
        :helper
      when /lib/
        :library
      when /spec|test/
        :test
      else
        :unknown
      end
    end

    def copy_directory_selectively(source, target, important_files = [])
      FileUtils.mkdir_p(target)
      
      Dir.glob(File.join(source, '**', '*')).each do |source_file|
        next unless File.file?(source_file)
        
        relative_path = source_file.sub(source + '/', '')
        target_file = File.join(target, relative_path)
        
        # Always copy important files, selectively copy others
        should_copy = important_files.any? { |imp| source_file.include?(imp) } ||
                     source_file.end_with?('.rb') ||
                     File.basename(source_file).match?(/^[A-Z]/) # Likely constants/classes
        
        if should_copy
          FileUtils.mkdir_p(File.dirname(target_file))
          FileUtils.cp(source_file, target_file)
        end
      end
    end
  end
end

