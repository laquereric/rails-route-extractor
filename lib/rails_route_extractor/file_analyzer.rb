# frozen_string_literal: true

module RailsRouteExtractor
  class FileAnalyzer
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def find_model_files(route)
    end

    def find_view_files(route)
    end

    def find_controller_files(route)
    end

    def analyze_file_content(file_path)
    end

    def extract_dependencies(content)
    end

    def find_partial_files(content)
    end

    def find_helper_files(route)
    end

    def find_concern_files(route)
    end

    def analyze_associations(content)
    end

    def generate_file_summary(file_path)
    end

    # Analyze a single file for dependencies and complexity
    def analyze_file(file_path)
      return {} unless File.exist?(file_path)

      content = File.read(file_path)
      
      {
        path: file_path,
        type: determine_file_type(file_path),
        size: File.size(file_path),
        lines: analyze_lines(content),
        complexity: analyze_complexity(content),
        dependencies: analyze_dependencies(content),
        patterns: analyze_patterns(content),
        security: analyze_security_patterns(content),
        performance: analyze_performance_patterns(content)
      }
    end

    # Analyze multiple files and create a comprehensive report
    def analyze_files(file_paths)
      results = {
        files: [],
        summary: {
          total_files: file_paths.length,
          total_size: 0,
          total_lines: 0,
          file_types: Hash.new(0),
          complexity_distribution: Hash.new(0),
          common_dependencies: Hash.new(0),
          security_issues: [],
          performance_issues: []
        }
      }

      file_paths.each do |file_path|
        analysis = analyze_file(file_path)
        results[:files] << analysis

        # Update summary
        results[:summary][:total_size] += analysis[:size]
        results[:summary][:total_lines] += analysis[:lines][:total]
        results[:summary][:file_types][analysis[:type]] += 1
        
        complexity_level = categorize_complexity(analysis[:complexity][:cyclomatic])
        results[:summary][:complexity_distribution][complexity_level] += 1
        
        analysis[:dependencies][:gems].each do |gem|
          results[:summary][:common_dependencies][gem] += 1
        end
        
        results[:summary][:security_issues].concat(analysis[:security][:issues])
        results[:summary][:performance_issues].concat(analysis[:performance][:issues])
      end

      # Sort common dependencies by frequency
      results[:summary][:common_dependencies] = results[:summary][:common_dependencies]
        .sort_by { |_, count| -count }
        .to_h

      results
    end

    # Create a dependency matrix showing relationships between files
    def create_dependency_matrix(file_paths)
      matrix = {}
      
      file_paths.each do |file_path|
        analysis = analyze_file(file_path)
        matrix[file_path] = {
          depends_on: [],
          depended_by: []
        }
        
        # Find dependencies within the analyzed files
        analysis[:dependencies][:requires].each do |required_file|
          resolved_path = resolve_require_path(required_file, file_paths)
          if resolved_path
            matrix[file_path][:depends_on] << resolved_path
          end
        end
      end
      
      # Build reverse dependencies
      matrix.each do |file, data|
        data[:depends_on].each do |dependency|
          if matrix[dependency]
            matrix[dependency][:depended_by] << file
          end
        end
      end
      
      matrix
    end

    # Suggest optimizations based on analysis
    def suggest_optimizations(analysis_results)
      suggestions = {
        complexity: [],
        dependencies: [],
        security: [],
        performance: [],
        maintainability: []
      }

      analysis_results[:files].each do |file_analysis|
        file_path = file_analysis[:path]
        
        # Complexity suggestions
        if file_analysis[:complexity][:cyclomatic] > 10
          suggestions[:complexity] << {
            file: file_path,
            issue: "High cyclomatic complexity (#{file_analysis[:complexity][:cyclomatic]})",
            suggestion: "Consider breaking down complex methods into smaller ones"
          }
        end
        
        if file_analysis[:complexity][:nesting_depth] > 4
          suggestions[:complexity] << {
            file: file_path,
            issue: "Deep nesting (#{file_analysis[:complexity][:nesting_depth]} levels)",
            suggestion: "Consider extracting nested logic into separate methods"
          }
        end
        
        # Dependency suggestions
        if file_analysis[:dependencies][:gems].length > 10
          suggestions[:dependencies] << {
            file: file_path,
            issue: "Many gem dependencies (#{file_analysis[:dependencies][:gems].length})",
            suggestion: "Review if all dependencies are necessary"
          }
        end
        
        # Security suggestions
        file_analysis[:security][:issues].each do |issue|
          suggestions[:security] << {
            file: file_path,
            issue: issue[:description],
            suggestion: issue[:suggestion]
          }
        end
        
        # Performance suggestions
        file_analysis[:performance][:issues].each do |issue|
          suggestions[:performance] << {
            file: file_path,
            issue: issue[:description],
            suggestion: issue[:suggestion]
          }
        end
        
        # Maintainability suggestions
        if file_analysis[:lines][:code] > 500
          suggestions[:maintainability] << {
            file: file_path,
            issue: "Large file (#{file_analysis[:lines][:code]} lines of code)",
            suggestion: "Consider splitting into smaller, more focused files"
          }
        end
      end

      suggestions
    end

    private

    def determine_file_type(file_path)
      case file_path
      when /controllers.*\.rb$/
        :controller
      when /models.*\.rb$/
        :model
      when /views.*\.(erb|haml|slim)$/
        :view
      when /helpers.*\.rb$/
        :helper
      when /lib.*\.rb$/
        :library
      when /spec.*\.rb$/
        :spec
      when /test.*\.rb$/
        :test
      when /concerns.*\.rb$/
        :concern
      when /\.rake$/
        :rake_task
      when /Gemfile/
        :gemfile
      when /\.gemspec$/
        :gemspec
      else
        :ruby
      end
    end

    def analyze_lines(content)
      lines = content.lines
      
      {
        total: lines.count,
        code: lines.count { |line| !line.strip.empty? && !line.strip.start_with?('#') },
        comments: lines.count { |line| line.strip.start_with?('#') },
        blank: lines.count { |line| line.strip.empty? }
      }
    end

    def analyze_complexity(content)
      {
        cyclomatic: calculate_cyclomatic_complexity(content),
        nesting_depth: calculate_nesting_depth(content),
        method_count: content.scan(/^\s*def\s+/).count,
        class_count: content.scan(/^\s*class\s+/).count,
        module_count: content.scan(/^\s*module\s+/).count
      }
    end

    def analyze_dependencies(content)
      {
        requires: extract_requires(content),
        includes: extract_includes(content),
        extends: extract_extends(content),
        gems: extract_gem_references(content),
        constants: extract_constant_references(content)
      }
    end

    def analyze_patterns(content)
      patterns = {
        design_patterns: [],
        rails_patterns: [],
        anti_patterns: []
      }

      # Design patterns
      patterns[:design_patterns] << 'Observer' if content.match?(/include\s+Observable|add_observer/)
      patterns[:design_patterns] << 'Singleton' if content.match?(/include\s+Singleton/)
      patterns[:design_patterns] << 'Factory' if content.match?(/def\s+create|def\s+build/)
      patterns[:design_patterns] << 'Decorator' if content.match?(/SimpleDelegator|delegate/)

      # Rails patterns
      patterns[:rails_patterns] << 'Concern' if content.match?(/extend\s+ActiveSupport::Concern/)
      patterns[:rails_patterns] << 'Callback' if content.match?(/before_|after_|around_/)
      patterns[:rails_patterns] << 'Validation' if content.match?(/validates|validate/)
      patterns[:rails_patterns] << 'Association' if content.match?(/belongs_to|has_many|has_one/)
      patterns[:rails_patterns] << 'Scope' if content.match?(/scope\s+:/)

      # Anti-patterns
      patterns[:anti_patterns] << 'God Object' if content.scan(/^\s*def\s+/).count > 20
      patterns[:anti_patterns] << 'Long Parameter List' if content.match?(/def\s+\w+\([^)]{50,}/)
      patterns[:anti_patterns] << 'Feature Envy' if content.scan(/\w+\.\w+\.\w+/).count > 10

      patterns
    end

    def analyze_security_patterns(content)
      issues = []

      # SQL injection risks
      if content.match?(/where\s*\(\s*["'][^"']*#\{/)
        issues << {
          type: 'sql_injection',
          description: 'Potential SQL injection vulnerability',
          suggestion: 'Use parameterized queries instead of string interpolation'
        }
      end

      # Mass assignment risks
      if content.match?(/params\[:?\w+\]\.permit!/)
        issues << {
          type: 'mass_assignment',
          description: 'Unsafe mass assignment with permit!',
          suggestion: 'Use specific parameter whitelisting instead of permit!'
        }
      end

      # XSS risks
      if content.match?(/\.html_safe|raw\s*\(/)
        issues << {
          type: 'xss',
          description: 'Potential XSS vulnerability',
          suggestion: 'Ensure content is properly sanitized before marking as html_safe'
        }
      end

      # Hardcoded secrets
      if content.match?(/(password|secret|key|token)\s*=\s*["'].+?["']/)
        issues << {
          type: 'hardcoded_secret',
          description: 'Potential hardcoded secret',
          suggestion: 'Use environment variables or encrypted credentials'
        }
      end

      { issues: issues }
    end

    def analyze_performance_patterns(content)
      issues = []

      # N+1 query risks
      if content.match?(/\.each\s*do.*\.\w+\.find/)
        issues << {
          type: 'n_plus_one',
          description: 'Potential N+1 query pattern',
          suggestion: 'Use includes, joins, or preload to avoid N+1 queries'
        }
      end

      # Inefficient loops
      if content.match?(/\.each\s*do.*\.save/)
        issues << {
          type: 'inefficient_loop',
          description: 'Individual saves in loop',
          suggestion: 'Consider using bulk operations like insert_all or update_all'
        }
      end

      # Memory leaks
      if content.match?(/@@\w+\s*=|class_variable_set/)
        issues << {
          type: 'memory_leak',
          description: 'Class variable usage',
          suggestion: 'Consider using class instance variables or constants instead'
        }
      end

      { issues: issues }
    end

    def calculate_cyclomatic_complexity(content)
      complexity = 1 # Base complexity
      
      # Add complexity for control structures
      complexity += content.scan(/\b(?:if|unless|while|until|for|case|rescue)\b/).count
      complexity += content.scan(/\b(?:elsif|when|rescue)\b/).count
      complexity += content.scan(/&&|\|\|/).count
      
      complexity
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

    def extract_requires(content)
      requires = []
      
      content.scan(/require\s+['"]([^'"]+)['"]/) do |match|
        requires << match[0]
      end
      
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

    def extract_gem_references(content)
      gems = []
      
      # Common gem patterns
      gem_patterns = {
        'devise' => /devise|authenticate_user|current_user/,
        'kaminari' => /paginate|page\(/,
        'cancancan' => /can\?|cannot\?|authorize!/,
        'sidekiq' => /perform_async|Sidekiq/,
        'redis' => /Redis/,
        'elasticsearch' => /Elasticsearch/
      }
      
      gem_patterns.each do |gem_name, pattern|
        if content.match?(pattern)
          gems << gem_name
        end
      end
      
      gems.uniq
    end

    def extract_constant_references(content)
      constants = []
      
      content.scan(/\b([A-Z][a-zA-Z0-9_]*(?:::[A-Z][a-zA-Z0-9_]*)*)\b/) do |match|
        constant = match[0]
        # Skip common Ruby constants
        next if %w[String Array Hash File Dir Time Date DateTime].include?(constant)
        constants << constant
      end
      
      constants.uniq
    end

    def categorize_complexity(cyclomatic_complexity)
      case cyclomatic_complexity
      when 1..5
        :low
      when 6..10
        :moderate
      when 11..20
        :high
      else
        :very_high
      end
    end

    def resolve_require_path(require_string, file_paths)
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

