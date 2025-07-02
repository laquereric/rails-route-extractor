# RailsRouteExtractor

RailsRouteExtractor is a comprehensive Ruby gem that provides rake tasks for Rails applications to extract Model, View, Controller (MVC) code required for specific routes. Building on the capabilities of `rails_route_tester` and `codeql_db`, it offers intelligent code extraction with dependency tracking and gem source file inclusion.

## Features

- **Route-based Extraction**: Extract MVC code for specific routes or route patterns
- **Flexible Extraction Modes**: Support for M, V, C, MV, MC, VC, or full MVC extraction
- **Multiple Output Formats**: List routes in text, JSON, CSV, or HTML formats
- **Advanced Filtering**: Filter routes by pattern, controller, or HTTP method
- **Detailed Route Information**: View associated files (models, views, controllers) for routes
- **Route Validation**: Validate route patterns against available routes
- **Route Statistics**: Analyze route distribution and usage patterns
- **Dependency Tracking**: Automatically include referenced gem source files
- **Intelligent Analysis**: Leverages CodeQL for comprehensive code analysis
- **Rails Integration**: Seamless integration with Rails applications via Railtie
- **CLI Interface**: Full-featured command-line interface
- **Rake Tasks**: Convenient rake tasks for common operations
- **Organized Output**: Structured extraction storage in 'route_extracts' folder

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_route_extractor'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install rails_route_extractor
```

## Usage

> **Breaking Change**: The `rails_route_extractor:list` rake task has been moved to `rails_route_extractor:list:text` and now supports multiple output formats and filtering options. Update your scripts accordingly.

### Command Line Interface

```bash
# Extract MVC code for a specific route
rails_route_extractor extract "users#index"

# Extract only models and views
rails_route_extractor extract "users#show" --mode mv

# Extract multiple routes
rails_route_extractor extract_multiple "users#index,users#show,posts#index"

# List all available routes (text format)
rails_route_extractor list

# List routes with filtering
rails_route_extractor list --pattern users              # Filter by pattern
rails_route_extractor list --controller users           # Filter by controller  
rails_route_extractor list --method GET                 # Filter by HTTP method

# List routes in different formats
rails_route_extractor list --format json                # JSON format
rails_route_extractor list --format csv                 # CSV format  
rails_route_extractor list --format html                # HTML format
rails_route_extractor list --format json --detailed     # JSON with detailed info

# Get detailed route information
rails_route_extractor info "users#index"

# Show route statistics
rails_route_extractor stats

# Validate route patterns
rails_route_extractor validate "users#index,posts#show"

# Clean up old extracts
rails_route_extractor cleanup --older_than 7d
```

### Rake Tasks

```bash
# Extract MVC code for a route
rake rails_route_extractor:extract[users#index]

# Extract with specific mode
rake rails_route_extractor:extract[users#show,mv]

# Extract multiple routes
rake rails_route_extractor:extract_multiple[users#index,users#show]

# List all routes in text format
rake rails_route_extractor:list:text

# List routes with filtering
rake rails_route_extractor:list:text[users]                    # Filter by pattern
rake rails_route_extractor:list:text[,users_controller]        # Filter by controller
rake rails_route_extractor:list:text[,,GET]                    # Filter by HTTP method

# List routes in different formats
rake rails_route_extractor:list:json                           # JSON format
rake rails_route_extractor:list:json[,,GET,true]              # JSON with detailed info
rake rails_route_extractor:list:csv                           # CSV format
rake rails_route_extractor:list:html                          # HTML format
rake rails_route_extractor:list:html[users,,true]             # HTML with detailed info

# Show route statistics
rake rails_route_extractor:stats

# Validate route patterns
rake rails_route_extractor:validate[users#index,posts#show]

# Clean up extracts
rake rails_route_extractor:cleanup
```

#### Route Listing Options

The route listing tasks support multiple output formats and filtering options:

**Output Formats:**
- `list:text` - Formatted table output (default)
- `list:json` - JSON format for programmatic use
- `list:csv` - CSV format for spreadsheets and data analysis
- `list:html` - Styled HTML table with modern CSS

**Filtering Parameters:**
- `pattern` - Search across controller, action, path, and route name
- `controller` - Filter by specific controller name
- `method` - Filter by HTTP method (GET, POST, PUT, DELETE, etc.)
- `detailed` - Include associated files information (JSON/HTML only)

**Examples:**
```bash
# Basic text listing
rake rails_route_extractor:list:text

# Find routes containing "user"
rake rails_route_extractor:list:text[user]

# Show only GET routes for users controller
rake rails_route_extractor:list:json[,users,GET]

# Generate HTML report with file associations
rake rails_route_extractor:list:html[,,true]

# Export to CSV
rake rails_route_extractor:list:csv > routes.csv
```

### Ruby API

```ruby
require 'rails_route_extractor'

# Configure the gem
RailsRouteExtractor.configure do |config|
  config.extract_base_path = "custom_extracts"
  config.include_gems = true
  config.verbose = true
end

# Extract a single route
result = RailsRouteExtractor.extract_route("users#index", mode: "mvc")

# Extract multiple routes
results = RailsRouteExtractor.extract_routes(["users#index", "posts#show"])

# List available routes
routes = RailsRouteExtractor.list_routes

# List routes with filtering
filtered_routes = RailsRouteExtractor.list_routes.select do |route|
  route[:controller]&.include?("users")
end

# Get route information with file associations
info = RailsRouteExtractor.route_info("users#index")

# Validate route patterns
valid_routes = ["users#index", "posts#show"]
available_routes = RailsRouteExtractor.list_routes.map { |r| "#{r[:controller]}##{r[:action]}" }
valid = valid_routes.all? { |route| available_routes.include?(route) }
```

## Configuration

RailsRouteExtractor can be configured through an initializer in Rails applications:

```ruby
# config/initializers/rails_route_extractor.rb
RailsRouteExtractor.configure do |config|
  # Base path for extracts (relative to Rails.root)
  config.extract_base_path = "route_extracts"
  
  # What to include in extracts
  config.include_models = true
  config.include_views = true
  config.include_controllers = true
  config.include_gems = true
  config.include_tests = false
  
  # Analysis options
  config.max_depth = 5
  config.follow_associations = true
  config.include_partials = true
  config.include_helpers = true
  config.include_concerns = true
  
  # Output options
  config.verbose = false
  config.compress_extracts = false
  config.manifest_format = :json
  
  # Exclusion patterns
  config.exclude_patterns += %w[
    custom_exclude_pattern
  ]
end
```

## Extraction Modes

RailsRouteExtractor supports several extraction modes:

- **`mvc`** (default): Extract Models, Views, and Controllers
- **`m`**: Extract Models only
- **`v`**: Extract Views only  
- **`c`**: Extract Controllers only
- **`mv`**: Extract Models and Views
- **`mc`**: Extract Models and Controllers
- **`vc`**: Extract Views and Controllers

## Output Structure

Extracts are organized in a structured directory format:

```
route_extracts/
├── users_index_20231127_143022/
│   ├── models/
│   │   ├── user.rb
│   │   └── concerns/
│   ├── views/
│   │   ├── users/
│   │   │   ├── index.html.erb
│   │   │   └── _user.html.erb
│   │   └── layouts/
│   ├── controllers/
│   │   ├── users_controller.rb
│   │   └── concerns/
│   ├── gems/
│   │   ├── devise/
│   │   └── kaminari/
│   └── manifest.json
└── posts_show_20231127_143045/
    └── ...
```

## Dependencies

RailsRouteExtractor builds upon these excellent gems:

- **rails_route_tester**: For route analysis and testing capabilities
- **codeql_db**: For comprehensive code analysis and dependency tracking
- **thor**: For CLI interface
- **activesupport**: For Rails integration

## Development

After checking out the repo, run:

```bash
bundle install
```

To run the tests:

```bash
rspec
```

To run Cucumber features:

```bash
cucumber
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

