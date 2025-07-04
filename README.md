# RailsRouteExtractor

RailsRouteExtractor is a comprehensive Ruby gem that provides rake tasks for Rails applications to extract Model, View, Controller (MVC) code required for specific routes. Building on the capabilities of `rails_route_tester` and `codeql_db`, it offers intelligent code extraction with dependency tracking and gem source file inclusion.

## Features

- **Route-based Extraction**: Extract MVC code for specific routes or route patterns
- **Flexible Extraction Modes**: Support for M, V, C, MV, MC, VC, or full MVC extraction
- **Multiple Output Formats**: List routes in text, JSON, CSV, HTML, or YAML formats
- **Route Cataloging**: Create hierarchical route catalogs organized by any parameter combination
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

# Create route catalogs organized by parameters
rake rails_route_extractor:catalog:by_param:text[controller,action]
rake rails_route_extractor:catalog:by_param:json[method,controller]
rake rails_route_extractor:catalog:by_param:html[controller]
rake rails_route_extractor:catalog:by_param:yaml[controller,action,method]

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

#### Route Catalog Options

The catalog tasks create hierarchical views of routes organized by specified parameters:

**Available Formats:**
- `catalog:by_param:text` - Hierarchical text tree output
- `catalog:by_param:json` - JSON structure with nested organization
- `catalog:by_param:html` - Interactive HTML with styled hierarchy
- `catalog:by_param:yaml` - YAML format for configuration files

**Parameter Hierarchy:**
The first parameter is the parameter path (comma-separated), which defines the hierarchy levels:
- `controller` - Group by controller name
- `action` - Group by action name
- `method` - Group by HTTP method
- `name` - Group by route name

**Examples:**
```bash
# Basic controller-action hierarchy
rake rails_route_extractor:catalog:by_param:text[controller,action]

# Group by HTTP method first, then controller
rake rails_route_extractor:catalog:by_param:json[method,controller]

# Single-level grouping by controller
rake rails_route_extractor:catalog:by_param:html[controller]

# Three-level hierarchy: controller > action > method
rake rails_route_extractor:catalog:by_param:yaml[controller,action,method]

# With filtering (same as list tasks)
rake rails_route_extractor:catalog:by_param:text[controller,action,users]  # Filter by pattern
rake rails_route_extractor:catalog:by_param:json[method,,admin]           # Filter by controller
```

**Sample Text Output:**
```
Route Catalog by controller > action
================================================================================
Total routes: 24
================================================================================

controller: users (8 routes)
  action: index (2 routes)
    - GET /users -> users#index
    - GET /admin/users -> admin/users#index
  action: show (2 routes)
    - GET /users/:id -> users#show
    - GET /admin/users/:id -> admin/users#show
  action: create (2 routes)
    - POST /users -> users#create
    - POST /admin/users -> admin/users#create

controller: posts (6 routes)
  action: index (1 routes)
    - GET /posts -> posts#index
  action: show (1 routes)
    - GET /posts/:id -> posts#show
```

#### JSON Output Examples

The JSON format provides structured data that's perfect for programmatic access and integration with other tools.

**Basic JSON Output:**
```bash
rake rails_route_extractor:list:json
```

```json
[
  {
    "pattern": "users",
    "controller": "users",
    "action": "index",
    "method": "GET",
    "name": "users",
    "helper": "users_path",
    "path": "/users(.:format)",
    "requirements": {
      "controller": "users",
      "action": "index"
    },
    "constraints": {}
  },
  {
    "pattern": "users/new",
    "controller": "users",
    "action": "new",
    "method": "GET",
    "name": "new_user",
    "helper": "new_user_path",
    "path": "/users/new(.:format)",
    "requirements": {
      "controller": "users",
      "action": "new"
    },
    "constraints": {}
  },
  {
    "pattern": "users",
    "controller": "users",
    "action": "create",
    "method": "POST",
    "name": "users",
    "helper": "users_path",
    "path": "/users(.:format)",
    "requirements": {
      "controller": "users",
      "action": "create"
    },
    "constraints": {}
  }
]
```

**Filtered JSON Output:**
```bash
# Get only POST routes
rake rails_route_extractor:list:json[,,POST]
```

```json
[
  {
    "pattern": "users",
    "controller": "users",
    "action": "create",
    "method": "POST",
    "name": "users",
    "helper": "users_path",
    "path": "/users(.:format)",
    "requirements": {
      "controller": "users",
      "action": "create"
    },
    "constraints": {}
  },
  {
    "pattern": "posts",
    "controller": "posts",
    "action": "create",
    "method": "POST",
    "name": "posts",
    "helper": "posts_path",
    "path": "/posts(.:format)",
    "requirements": {
      "controller": "posts",
      "action": "create"
    },
    "constraints": {}
  }
]
```

**Detailed JSON Output with File Associations:**
```bash
rake rails_route_extractor:list:json[,,true]
```

```json
[
  {
    "pattern": "users",
    "controller": "users",
    "action": "index",
    "method": "GET",
    "name": "users",
    "helper": "users_path",
    "path": "/users(.:format)",
    "requirements": {
      "controller": "users",
      "action": "index"
    },
    "constraints": {},
    "detailed_info": {
      "pattern": "users#index",
      "controller": "users",
      "action": "index",
      "method": "GET",
      "name": "users",
      "helper": "users_path",
      "path": "/users(.:format)",
      "requirements": {
        "controller": "users",
        "action": "index"
      },
      "constraints": {},
      "files": {
        "models": [
          "app/models/user.rb",
          "app/models/concerns/authenticatable.rb"
        ],
        "views": [
          "app/views/users/index.html.erb",
          "app/views/users/_user.html.erb",
          "app/views/layouts/application.html.erb"
        ],
        "controllers": [
          "app/controllers/users_controller.rb",
          "app/controllers/application_controller.rb",
          "app/controllers/concerns/authentication.rb"
        ],
        "helpers": [
          "app/helpers/users_helper.rb",
          "app/helpers/application_helper.rb"
        ],
        "concerns": [
          "app/models/concerns/authenticatable.rb",
          "app/controllers/concerns/authentication.rb"
        ]
      }
    }
  }
]
```

**Pattern-Filtered JSON Output:**
```bash
# Find all routes containing "user"
rake rails_route_extractor:list:json[user]
```

```json
[
  {
    "pattern": "users",
    "controller": "users",
    "action": "index",
    "method": "GET",
    "name": "users",
    "helper": "users_path",
    "path": "/users(.:format)",
    "requirements": {
      "controller": "users",
      "action": "index"
    },
    "constraints": {}
  },
  {
    "pattern": "users/:id",
    "controller": "users",
    "action": "show",
    "method": "GET",
    "name": "user",
    "helper": "user_path",
    "path": "/users/:id(.:format)",
    "requirements": {
      "controller": "users",
      "action": "show"
    },
    "constraints": {}
  },
  {
    "pattern": "admin/users",
    "controller": "admin/users",
    "action": "index",
    "method": "GET",
    "name": "admin_users",
    "helper": "admin_users_path",
    "path": "/admin/users(.:format)",
    "requirements": {
      "controller": "admin/users",
      "action": "index"
    },
    "constraints": {}
  }
]
```

**Error Handling:**
If there's an error during route extraction, the JSON output will contain error information:

```json
{
  "error": "Rails application not found. Make sure you're running this in a Rails environment."
}
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

# Advanced route analysis
routes = RailsRouteExtractor.list_routes

# Group routes by controller
routes_by_controller = routes.group_by { |route| route[:controller] }

# Find all API routes
api_routes = routes.select { |route| route[:path].include?('/api/') }

# Get route statistics
stats = {
  total_routes: routes.length,
  unique_controllers: routes.map { |r| r[:controller] }.uniq.length,
  http_methods: routes.map { |r| r[:method] }.uniq,
  restful_routes: routes.select { |r| 
    %w[index show new create edit update destroy].include?(r[:action]) 
  }.length
}

# Find routes with specific patterns
admin_routes = routes.select { |r| r[:controller].start_with?('admin/') }
nested_routes = routes.select { |r| r[:controller].include?('/') }

# Export routes to different formats
require 'json'
require 'csv'

# JSON export
File.write('routes.json', JSON.pretty_generate(routes))

# CSV export  
CSV.open('routes.csv', 'w') do |csv|
  csv << ['Controller', 'Action', 'Method', 'Path', 'Name']
  routes.each do |route|
    csv << [route[:controller], route[:action], route[:method], 
            route[:path], route[:name]]
  end
end
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

### Working with Catalog Data

The catalog functionality can also be used programmatically for advanced route analysis:

```ruby
# Generate catalog data directly
routes = RailsRouteExtractor.list_routes
param_paths = ['controller', 'action']

# Build the catalog structure
catalog = {}
routes.each do |route|
  controller = route[:controller]
  action = route[:action]
  
  catalog[controller] ||= {}
  catalog[controller][action] ||= []
  catalog[controller][action] << route
end

# Analyze the catalog
controller_stats = catalog.map do |controller, actions|
  {
    controller: controller,
    action_count: actions.keys.length,
    route_count: actions.values.flatten.length,
    actions: actions.keys
  }
end

# Find controllers with the most actions
top_controllers = controller_stats.sort_by { |c| -c[:action_count] }

# Generate custom reports
puts "Controllers by complexity:"
top_controllers.each do |stats|
  puts "#{stats[:controller]}: #{stats[:action_count]} actions, #{stats[:route_count]} routes"
end
```

**Shell Processing with jq:**
```bash
# Get catalog data and analyze with jq
rake rails_route_extractor:catalog:by_param:json[controller,action] > catalog.json

# Count routes per controller
jq '.catalog | to_entries | map({controller: .key, total_routes: [.value | to_entries[].value | length] | add}) | sort_by(-.total_routes)' catalog.json

# List all actions for a specific controller
jq '.catalog.users | keys' catalog.json

# Find controllers with specific actions
jq '.catalog | to_entries | map(select(.value | has("index"))) | map(.key)' catalog.json
```

