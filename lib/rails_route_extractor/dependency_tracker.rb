# frozen_string_literal: true

require 'find'
require 'set'

module RailsRouteExtractor
  class DependencyTracker
    attr_reader :config

    def initialize(config)
      @config = config
    end

    # Track dependencies for a specific file
    def track_file_dependencies(file_path)
      return {} unless File.exist?(file_path)

      dependencies = {
        requires: [],
        includes: [],
        extends: [],
        models: [],
        gems: [],
        constants: [],
        method_calls: []
      }

      content = File.read(file_path)
      
      # Track require statements
      dependencies[:requires] = extract_requires(content)
      
      # Track include/extend statements
      dependencies[:includes] = extract_includes(content)
      dependencies[:extends] = extract_extends(content)
      
      # Track model references
      dependencies[:models] = extract_model_references(content)
      
      # Track gem usage
      dependencies[:gems] = extract_gem_usage(content)
      
      # Track constant references
      dependencies[:constants] = extract_constants(content)
      
      # Track method calls that might indicate dependencies
      dependencies[:method_calls] = extract_method_calls(content)

      dependencies
    end

    # Track dependencies for multiple files
    def track_dependencies(file_paths)
      all_dependencies = {
        requires: Set.new,
        includes: Set.new,
        extends: Set.new,
        models: Set.new,
        gems: Set.new,
        constants: Set.new,
        method_calls: Set.new
      }

      file_paths.each do |file_path|
        file_deps = track_file_dependencies(file_path)
        
        file_deps.each do |type, deps|
          all_dependencies[type].merge(deps)
        end
      end

      # Convert sets back to arrays and sort
      all_dependencies.transform_values { |set| set.to_a.sort }
    end

    # Get gem source files for dependencies
    def get_gem_source_files(gem_names)
      gem_files = {}

      gem_names.each do |gem_name|
        begin
          gem_spec = Gem::Specification.find_by_name(gem_name)
          gem_files[gem_name] = {
            version: gem_spec.version.to_s,
            path: gem_spec.gem_dir,
            lib_files: find_gem_lib_files(gem_spec),
            essential_files: find_gem_essential_files(gem_spec)
          }
        rescue Gem::LoadError
          puts "Warning: Gem not found: #{gem_name}" if config.verbose
          gem_files[gem_name] = {
            error: "Gem not found",
            version: nil,
            path: nil,
            lib_files: [],
            essential_files: []
          }
        end
      end

      gem_files
    end

    # Analyze code complexity and dependencies using CodeQL-like analysis
    def analyze_code_complexity(file_path)
      return {} unless File.exist?(file_path)

      content = File.read(file_path)
      
      {
        lines_of_code: count_lines_of_code(content),
        cyclomatic_complexity: calculate_cyclomatic_complexity(content),
        method_count: count_methods(content),
        class_count: count_classes(content),
        dependency_count: count_dependencies(content),
        nesting_depth: calculate_nesting_depth(content)
      }
    end

    # Find all Ruby files that might be dependencies
    def find_dependency_files(root_path, exclude_patterns = [])
      ruby_files = []
      
      Find.find(root_path) do |path|
        # Skip excluded patterns
        if exclude_patterns.any? { |pattern| path.include?(pattern) }
          Find.prune if File.directory?(path)
          next
        end
        
        # Include Ruby files
        if File.file?(path) && ruby_file?(path)
          ruby_files << path
        end
      end
      
      ruby_files.sort
    end

    # Create a dependency graph
    def create_dependency_graph(file_paths)
      graph = {}
      
      file_paths.each do |file_path|
        dependencies = track_file_dependencies(file_path)
        
        graph[file_path] = {
          dependencies: dependencies,
          dependents: []
        }
      end
      
      # Build reverse dependencies (dependents)
      graph.each do |file, data|
        data[:dependencies][:requires].each do |required_file|
          # Find the actual file path for the require
          actual_path = resolve_require_path(required_file, file_paths)
          if actual_path && graph[actual_path]
            graph[actual_path][:dependents] << file
          end
        end
      end
      
      graph
    end

    private

    def extract_requires(content)
      requires = []
      
      # Match require statements
      content.scan(/require\s+['"]([^'"]+)['"]/) do |match|
        requires << match[0]
      end
      
      # Match require_relative statements
      content.scan(/require_relative\s+['"]([^'"]+)['"]/) do |match|
        requires << match[0]
      end
      
      requires.uniq
    end

    def extract_includes(content)
      includes = []
      
      content.scan(/include\s+([A-Z][a-zA-Z0-9_:]*)\b/) do |match|
        includes << match[0]
      end
      
      includes.uniq
    end

    def extract_extends(content)
      extends = []
      
      content.scan(/extend\s+([A-Z][a-zA-Z0-9_:]*)\b/) do |match|
        extends << match[0]
      end
      
      extends.uniq
    end

    def extract_model_references(content)
      models = []
      
      # Look for ActiveRecord-style method calls
      content.scan(/\b([A-Z][a-zA-Z0-9_]*)\.(find|where|create|new|all|first|last|count|exists\?|destroy|update|save)\b/) do |match|
        model_name = match[0]
        # Skip obvious non-model constants
        next if %w[File Dir String Array Hash Time Date DateTime].include?(model_name)
        models << model_name
      end
      
      # Look for associations
      content.scan(/(?:belongs_to|has_many|has_one|has_and_belongs_to_many)\s+:([a-zA-Z0-9_]+)/) do |match|
        association_name = match[0]
        model_name = association_name.classify
        models << model_name
      end
      
      models.uniq
    end

    def extract_gem_usage(content)
      gems = []
      
      # Look for gem-specific patterns
      gem_patterns = {
        'devise' => /devise|authenticate_user|current_user|user_signed_in\?/,
        'kaminari' => /paginate|page\(/,
        'cancancan' => /can\?|cannot\?|authorize!/,
        'paperclip' => /has_attached_file|attachment/,
        'carrierwave' => /mount_uploader/,
        'sidekiq' => /perform_async|Sidekiq/,
        'resque' => /Resque/,
        'redis' => /Redis/,
        'elasticsearch' => /Elasticsearch|__elasticsearch__/,
        'ransack' => /ransack|search\(/
      }
      
      gem_patterns.each do |gem_name, pattern|
        if content.match?(pattern)
          gems << gem_name
        end
      end
      
      gems.uniq
    end

    def extract_constants(content)
      constants = []
      
      # Find constant references (CamelCase)
      content.scan(/\b([A-Z][a-zA-Z0-9_]*(?:::[A-Z][a-zA-Z0-9_]*)*)\b/) do |match|
        constant = match[0]
        # Skip common Ruby constants and keywords
        next if %w[String Array Hash File Dir Time Date DateTime Class Module].include?(constant)
        constants << constant
      end
      
      constants.uniq
    end

    def extract_method_calls(content)
      method_calls = []
      
      # Extract method calls that might indicate dependencies
      dependency_methods = %w[
        render redirect_to respond_to format
        before_action after_action around_action
        validates validate presence length uniqueness
        scope default_scope
        serialize attr_accessor attr_reader attr_writer
      ]
      
      dependency_methods.each do |method|
        if content.include?(method)
          method_calls << method
        end
      end
      
      method_calls.uniq
    end

    def find_gem_lib_files(gem_spec)
      lib_files = []
      lib_path = File.join(gem_spec.gem_dir, 'lib')
      
      return lib_files unless Dir.exist?(lib_path)
      
      Dir.glob(File.join(lib_path, '**', '*.rb')).each do |file|
        relative_path = file.sub(gem_spec.gem_dir + '/', '')
        lib_files << relative_path
      end
      
      lib_files.sort
    end

    def find_gem_essential_files(gem_spec)
      essential_files = []
      essential_patterns = %w[
        README* LICENSE* CHANGELOG* HISTORY*
        *.gemspec Gemfile Rakefile
      ]
      
      essential_patterns.each do |pattern|
        Dir.glob(File.join(gem_spec.gem_dir, pattern)).each do |file|
          next unless File.file?(file)
          relative_path = file.sub(gem_spec.gem_dir + '/', '')
          essential_files << relative_path
        end
      end
      
      essential_files.sort
    end

    def count_lines_of_code(content)
      lines = content.lines
      {
        total: lines.count,
        code: lines.count { |line| !line.strip.empty? && !line.strip.start_with?('#') },
        comments: lines.count { |line| line.strip.start_with?('#') },
        blank: lines.count { |line| line.strip.empty? }
      }
    end

    def calculate_cyclomatic_complexity(content)
      # Simple cyclomatic complexity calculation
      complexity = 1 # Base complexity
      
      # Add complexity for control structures
      complexity += content.scan(/\b(?:if|unless|while|until|for|case|rescue)\b/).count
      complexity += content.scan(/\b(?:elsif|when|rescue)\b/).count
      complexity += content.scan(/&&|\|\|/).count
      
      complexity
    end

    def count_methods(content)
      content.scan(/^\s*def\s+/).count
    end

    def count_classes(content)
      content.scan(/^\s*class\s+/).count
    end

    def count_dependencies(content)
      requires = extract_requires(content)
      includes = extract_includes(content)
      extends = extract_extends(content)
      
      (requires + includes + extends).uniq.count
    end

    def calculate_nesting_depth(content)
      max_depth = 0
      current_depth = 0
      
      content.lines.each do |line|
        stripped = line.strip
        
        # Increase depth for opening constructs
        if stripped.match?(/\b(?:class|module|def|if|unless|while|until|for|case|begin)\b/)
          current_depth += 1
          max_depth = [max_depth, current_depth].max
        end
        
        # Decrease depth for closing constructs
        if stripped == 'end'
          current_depth -= 1
        end
      end
      
      max_depth
    end

    def ruby_file?(path)
      return true if path.end_with?('.rb')
      return true if path.end_with?('.rake')
      return true if File.basename(path) == 'Rakefile'
      return true if File.basename(path) == 'Gemfile'
      
      # Check shebang for Ruby files without extension
      if File.file?(path)
        first_line = File.open(path, &:readline) rescue nil
        return true if first_line&.include?('ruby')
      end
      
      false
    end

    def resolve_require_path(require_string, file_paths)
      # Try to resolve a require string to an actual file path
      possible_paths = [
        "#{require_string}.rb",
        "lib/#{require_string}.rb",
        "app/#{require_string}.rb"
      ]
      
      file_paths.find do |file_path|
        possible_paths.any? { |possible| file_path.end_with?(possible) }
      end
    end
  end
end

