# RailsRouteExtractor

RailsRouteExtractor is a comprehensive Ruby gem that provides rake tasks for Rails applications to extract Model, View, Controller (MVC) code required for specific routes. Building on the capabilities of `rails_route_tester` and `codeql_db`, it offers intelligent code extraction with dependency tracking and gem source file inclusion.

## Features

- **Route-based Extraction**: Extract MVC code for specific routes or route patterns
- **Flexible Extraction Modes**: Support for M, V, C, MV, MC, VC, or full MVC extraction
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

### Command Line Interface

```bash
# Extract MVC code for a specific route
rails_route_extractor extract "users#index"

# Extract only models and views
rails_route_extractor extract "users#show" --mode mv

# Extract multiple routes
rails_route_extractor extract_multiple "users#index,users#show,posts#index"

# List all available routes
rails_route_extractor list

# Get detailed route information
rails_route_extractor info "users#index"

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

# List all routes
rake rails_route_extractor:list

# Clean up extracts
rake rails_route_extractor:cleanup
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

# Get route information
info = RailsRouteExtractor.route_info("users#index")
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

