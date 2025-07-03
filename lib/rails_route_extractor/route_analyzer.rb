# frozen_string_literal: true

module RailsRouteExtractor
  class RouteAnalyzer
    attr_reader :config

    def initialize(config)
      @config = config
    end

    # List all available routes in the Rails application
    def list_routes
      ensure_rails_environment!
      
      routes = []
      # Iterate through all routes defined in the Rails application
      # Skip internal routes and redirects
      # Use a begin-rescue block to handle any errors gracefully
      # and continue processing other routes
      # Extract relevant information from each route
      # Sort routes by controller and action for easier navigation
      # Return an array of route hashes with detailed information
      # about each route, including controller, action, method, and path
      # Also include helper names and any additional metadata if available 
      Rails.application.routes.routes.each do |route|
        begin
          # Skip internal routes and redirects
          next if route.name && route.name.start_with?('rails_')
          
          next if route.path.spec.to_s.start_with?('/rails/')
          
          route_info = extract_route_info(route)
          routes << route_info if route_info
        rescue => e
          # Skip routes that cause errors and continue processing
          puts "Warning: Skipping route due to error: #{e.message}" if config.verbose
          next
        end
      end
      routes.sort_by { |r| [r[:controller], r[:action]] }
    end

    # Get detailed information about a specific route
    def route_info(route_pattern)
      ensure_rails_environment!
      
      routes = list_routes
      route = find_route_by_pattern(routes, route_pattern)
      
      return nil unless route
      
      # Enhance with file information
      route[:files] = {
        models: find_model_files(route),
        views: find_view_files(route),
        controllers: find_controller_files(route),
        helpers: find_helper_files(route),
        concerns: find_concern_files(route)
      }
      
      route
    end

    def analyze_route_complexity(route_pattern)
      dependencies = route_dependencies(route_pattern)
      return nil unless dependencies

      file_analyzer = FileAnalyzer.new(config)
      file_analysis = file_analyzer.analyze_files(dependencies.values.flatten.compact)

      {
        file_count: dependencies.values.flatten.compact.uniq.count,
        total_lines: file_analysis[:summary][:total_lines],
        gem_dependencies: dependencies[:gems].count,
        dependency_depth: 5 # Placeholder, actual calculation is complex
      }
    end

    def route_dependencies(route_pattern)
      route = route_info(route_pattern)
      return nil unless route

      files = route[:files].values.flatten.compact
      dependency_tracker = DependencyTracker.new(config)
      dependencies = dependency_tracker.track_dependencies(files)

      route[:files].merge(dependencies)
    end

    def analyze_route(route_pattern)
    end

    def find_route_files(route)
    end

    def validate_route_pattern(route_pattern)
    end

    def parse_route_pattern(route_pattern)
    end

    def get_route_metadata(route)
    end

    def extract_route_dependencies(route)
    end

    def generate_route_report(route)
    end

    # Find routes matching a pattern
    def find_routes_by_pattern(pattern)
      routes = list_routes
      
      if pattern.include?('#')
        # Controller#action format
        controller, action = pattern.split('#', 2)
        routes.select do |route|
          route[:controller].include?(controller) && 
          (action.nil? || route[:action] == action)
        end
      else
        # General pattern matching
        regex = Regexp.new(pattern, Regexp::IGNORECASE)
        routes.select do |route|
          route[:pattern].match?(regex) ||
          route[:controller].match?(regex) ||
          route[:action].match?(regex)
        end
      end
    end

    # Check if a route exists
    def route_exists?(route_pattern)
      routes = list_routes
      find_route_by_pattern(routes, route_pattern) != nil
    end

    # Get route dependencies (models, concerns, etc.)
    def route_dependencies(route_pattern)
      route = route_info(route_pattern)
      return {} unless route
      
      dependencies = {
        models: [],
        concerns: [],
        helpers: [],
        partials: [],
        gems: []
      }
      
      # Analyze controller dependencies
      if route[:files][:controllers].any?
        route[:files][:controllers].each do |controller_file|
          deps = analyze_file_dependencies(controller_file)
          dependencies[:models].concat(deps[:models])
          dependencies[:concerns].concat(deps[:concerns])
          dependencies[:gems].concat(deps[:gems])
        end
      end
      
      # Analyze view dependencies
      if route[:files][:views].any?
        route[:files][:views].each do |view_file|
          deps = analyze_file_dependencies(view_file)
          dependencies[:partials].concat(deps[:partials])
          dependencies[:helpers].concat(deps[:helpers])
          dependencies[:gems].concat(deps[:gems])
        end
      end
      
      # Remove duplicates and sort
      dependencies.each { |key, value| value.uniq!.sort! }
      
      dependencies
    end

    private

    def find_associated_files(controller, action)
      # This is a simplified placeholder. A real implementation would be more robust.
      {
        controllers: ["app/controllers/#{controller}_controller.rb"],
        models: ["app/models/#{controller.singularize}.rb"],
        views: ["app/views/#{controller}/#{action}.html.erb"],
        helpers: ["app/helpers/#{controller}_helper.rb"],
        concerns: []
      }
    end

    def extract_route_pattern(defaults)
      "#{defaults[:controller]}##{defaults[:action]}"
    end

    def extract_route_helper(name, method)
      return nil unless name
      # This is a simplification. Real helper generation is more complex.
      name.end_with?("s") || method == "POST" ? "#{name}_path" : "#{name.pluralize}_path"
    end

    def ensure_rails_environment!
      unless defined?(Rails) && Rails.respond_to?(:application) && Rails.application
        raise Error, "Rails application not found. Make sure you're running this in a Rails environment."
      end
    end

    def extract_route_info(route)
      begin
        # Skip routes without controller/action
        controller = route.requirements[:controller] || route.defaults[:controller]
        action = route.requirements[:action] || route.defaults[:action]
        
        return nil unless controller && action
        
        # Handle verb which might be a string or symbol, or might not exist
        verb = begin
          if route.respond_to?(:verb) && route.verb
            route.verb.respond_to?(:to_s) ? route.verb.to_s : route.verb.to_s
          else
            'GET'
          end
        rescue
          'GET'
        end
        
        # Safely get the path
        path = begin
          route.path.spec.to_s
        rescue
          route.path.to_s rescue '/'
        end
        
        {
          pattern: route_pattern(route),
          controller: controller,
          action: action,
          method: verb,
          name: route.name,
          helper: route.name ? "#{route.name}_path" : nil,
          path: path,
          requirements: route.requirements || {},
          constraints: route.constraints || {}
        }
      rescue => e
        # If we can't extract route info, return nil to skip this route
        puts "Warning: Could not extract info for route: #{e.message}" if config.verbose
        nil
      end
    end

    def route_pattern(route)
      begin
        # Clean up the route pattern for display
        pattern = route.path.spec.to_s
        pattern.gsub!(/\(\.:format\)$/, '')
        pattern.gsub!(/\A\//, '')
        pattern
      rescue
        # Fallback if we can't get the pattern
        controller = route.requirements[:controller] || route.defaults[:controller] || 'unknown'
        action = route.requirements[:action] || route.defaults[:action] || 'unknown'
        "#{controller}##{action}"
      end
    end

    def find_route_by_pattern(routes, pattern)
      if pattern.include?('#')
        controller, action = pattern.split('#', 2)
        routes.find do |route|
          route[:controller] == controller && route[:action] == action
        end
      else
        routes.find { |route| route[:pattern] == pattern || route[:name] == pattern }
      end
    end

    def find_model_files(route)
      files = []
      
      # Look for models based on controller name
      controller_name = route[:controller]
      model_name = controller_name.singularize.camelize
      
      model_file = Rails.root.join("app", "models", "#{model_name.underscore}.rb")
      files << model_file.to_s if model_file.exist?
      
      # Look for associated models (if we can infer them)
      if route[:action] == 'show' || route[:action] == 'edit' || route[:action] == 'update' || route[:action] == 'destroy'
        # These actions typically work with a single model instance
        files << model_file.to_s if model_file.exist?
      end
      
      files.uniq
    end

    def find_view_files(route)
      files = []
      
      controller_path = route[:controller]
      action = route[:action]
      
      # Main view file
      view_dir = Rails.root.join("app", "views", controller_path)
      if view_dir.exist?
        # Look for the action view with various extensions
        %w[html.erb html.haml html.slim json.jbuilder].each do |ext|
          view_file = view_dir.join("#{action}.#{ext}")
          files << view_file.to_s if view_file.exist?
        end
        
        # Look for partials in the same directory
        Dir.glob(view_dir.join("_*.{erb,haml,slim}")).each do |partial|
          files << partial
        end
      end
      
      # Layout files
      layout_dir = Rails.root.join("app", "views", "layouts")
      if layout_dir.exist?
        %w[application.html.erb application.html.haml application.html.slim].each do |layout|
          layout_file = layout_dir.join(layout)
          files << layout_file.to_s if layout_file.exist?
        end
      end
      
      files.uniq
    end

    def find_controller_files(route)
      files = []
      
      controller_name = route[:controller]
      controller_file = Rails.root.join("app", "controllers", "#{controller_name}_controller.rb")
      files << controller_file.to_s if controller_file.exist?
      
      # Application controller
      app_controller = Rails.root.join("app", "controllers", "application_controller.rb")
      files << app_controller.to_s if app_controller.exist?
      
      files.uniq
    end

    def find_helper_files(route)
      files = []
      
      controller_name = route[:controller]
      helper_file = Rails.root.join("app", "helpers", "#{controller_name}_helper.rb")
      files << helper_file.to_s if helper_file.exist?
      
      # Application helper
      app_helper = Rails.root.join("app", "helpers", "application_helper.rb")
      files << app_helper.to_s if app_helper.exist?
      
      files.uniq
    end

    def find_concern_files(route)
      files = []
      
      # Controller concerns
      concern_dir = Rails.root.join("app", "controllers", "concerns")
      if concern_dir.exist?
        Dir.glob(concern_dir.join("*.rb")).each do |concern|
          files << concern
        end
      end
      
      # Model concerns
      model_concern_dir = Rails.root.join("app", "models", "concerns")
      if model_concern_dir.exist?
        Dir.glob(model_concern_dir.join("*.rb")).each do |concern|
          files << concern
        end
      end
      
      files.uniq
    end

    def analyze_file_dependencies(file_path)
      dependencies = {
        models: [],
        concerns: [],
        helpers: [],
        partials: [],
        gems: []
      }
      
      return dependencies unless File.exist?(file_path)
      
      content = File.read(file_path)
      
      # Look for model references
      content.scan(/\b([A-Z][a-zA-Z]*)\.(find|where|create|new|all|first|last)\b/) do |match|
        model_name = match[0]
        model_file = Rails.root.join("app", "models", "#{model_name.underscore}.rb")
        dependencies[:models] << model_file.to_s if model_file.exist?
      end
      
      # Look for include/extend statements (concerns)
      content.scan(/(?:include|extend)\s+([A-Z][a-zA-Z:]*)\b/) do |match|
        concern_name = match[0]
        concern_file = find_concern_file(concern_name)
        dependencies[:concerns] << concern_file if concern_file
      end
      
      # Look for render partial calls
      content.scan(/render\s+(?:partial:\s*)?['"]([^'"]+)['"]/) do |match|
        partial_name = match[0]
        partial_file = find_partial_file(partial_name)
        dependencies[:partials] << partial_file if partial_file
      end
      
      # Look for gem usage (require statements)
      content.scan(/require\s+['"]([^'"]+)['"]/) do |match|
        gem_name = match[0]
        dependencies[:gems] << gem_name unless gem_name.start_with?('.')
      end
      
      dependencies
    end

    def find_concern_file(concern_name)
      # Try different possible locations for concerns
      possible_paths = [
        Rails.root.join("app", "controllers", "concerns", "#{concern_name.underscore}.rb"),
        Rails.root.join("app", "models", "concerns", "#{concern_name.underscore}.rb"),
        Rails.root.join("lib", "#{concern_name.underscore}.rb")
      ]
      
      possible_paths.find { |path| path.exist? }&.to_s
    end

    def find_partial_file(partial_name)
      # Handle different partial naming conventions
      if partial_name.include?('/')
        # Partial with path: 'shared/header'
        dir_path, file_name = partial_name.rsplit('/', 2)
        partial_path = Rails.root.join("app", "views", dir_path, "_#{file_name}.html.erb")
      else
        # Partial without path: 'header'
        partial_path = Rails.root.join("app", "views", "shared", "_#{partial_name}.html.erb")
      end
      
      partial_path.exist? ? partial_path.to_s : nil
    end
  end
end

