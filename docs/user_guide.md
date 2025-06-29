# RouteExtract User Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Quick Start](#quick-start)
4. [Configuration](#configuration)
5. [Command Line Interface](#command-line-interface)
6. [Rake Tasks](#rake-tasks)
7. [Ruby API](#ruby-api)
8. [Extraction Modes](#extraction-modes)
9. [Output Structure](#output-structure)
10. [Advanced Usage](#advanced-usage)
11. [Troubleshooting](#troubleshooting)
12. [Best Practices](#best-practices)

## Introduction

RouteExtract is a powerful Ruby gem designed to help Rails developers extract and analyze Model, View, Controller (MVC) code for specific routes. Built on top of `rails_route_tester` and `codeql_db`, it provides intelligent code extraction with comprehensive dependency tracking and gem source file inclusion.

### Key Features

- **Route-based Extraction**: Extract MVC code for specific routes or route patterns
- **Flexible Extraction Modes**: Support for M, V, C, MV, MC, VC, or full MVC extraction
- **Dependency Tracking**: Automatically include referenced gem source files
- **Intelligent Analysis**: Leverages CodeQL-like analysis for comprehensive code understanding
- **Rails Integration**: Seamless integration with Rails applications via Railtie
- **CLI Interface**: Full-featured command-line interface with Thor
- **Rake Tasks**: Convenient rake tasks for common operations
- **Organized Output**: Structured extraction storage in 'route_extracts' folder

### Use Cases

- **Code Review**: Extract specific route implementations for focused code reviews
- **Documentation**: Generate code samples for documentation purposes
- **Migration**: Extract code when migrating specific features to microservices
- **Analysis**: Analyze dependencies and complexity of specific application features
- **Learning**: Study how specific routes are implemented in large applications
- **Debugging**: Isolate code related to problematic routes for debugging

## Installation

### Prerequisites

- Ruby 3.0 or later
- Rails 6.0 or later
- Git (for development dependencies)

### Adding to Your Rails Application

Add this line to your application's Gemfile:

```ruby
gem 'route_extract'
```

And then execute:

```bash
bundle install
```

### Development Dependencies

For development and enhanced features, add these to your Gemfile's development group:

```ruby
group :development do
  gem 'rails_route_tester', git: 'https://github.com/laquereric/rails_route_tester'
  gem 'codeql_db', git: 'https://github.com/laquereric/codeql_db'
end
```

### Installation Generator

After adding the gem, run the install generator to set up configuration:

```bash
rails generate route_extract:install
```

This will:
- Create an initializer file at `config/initializers/route_extract.rb`
- Create the `route_extracts` directory
- Add `route_extracts/` to your `.gitignore`
- Display helpful next steps

## Quick Start

### Basic Route Extraction

Extract MVC code for a specific route:

```bash
# Using CLI
route_extract extract "users#index"

# Using rake task
rake route_extract:extract[users#index]
```

### Extract with Specific Mode

Extract only models and views:

```bash
# Using CLI
route_extract extract "users#show" --mode mv

# Using rake task
rake route_extract:extract[users#show,mv]
```

### List Available Routes

See all routes in your application:

```bash
# Using CLI
route_extract list

# Using rake task
rake route_extract:list
```

### Extract Multiple Routes

Extract several routes at once:

```bash
# Using CLI
route_extract extract_multiple "users#index,users#show,posts#index"

# Using rake task
rake route_extract:extract_multiple[users#index,users#show,posts#index]
```

## Configuration

RouteExtract can be configured through an initializer file. The install generator creates a default configuration at `config/initializers/route_extract.rb`.

### Basic Configuration

```ruby
RouteExtract.configure do |config|
  # Base path for extracts (relative to Rails.root)
  config.extract_base_path = "route_extracts"
  
  # What to include in extracts by default
  config.include_models = true
  config.include_views = true
  config.include_controllers = true
  config.include_gems = true
  config.include_tests = false
  
  # Enable verbose output
  config.verbose = false
end
```

### Advanced Configuration

```ruby
RouteExtract.configure do |config|
  # Analysis options
  config.max_depth = 5                    # Maximum dependency depth to follow
  config.follow_associations = true       # Follow ActiveRecord associations
  config.include_partials = true          # Include view partials
  config.include_helpers = true           # Include helper files
  config.include_concerns = true          # Include concerns
  
  # Output options
  config.compress_extracts = false        # Compress extracts into archives
  config.manifest_format = :json          # Manifest format (:json, :yaml)
  
  # Additional exclusion patterns
  config.exclude_patterns += %w[
    custom_exclude_pattern
    another_pattern
  ]
  
  # Custom gem source paths
  config.gem_source_paths = [
    "/custom/gem/path"
  ]
end
```

### Extraction Mode Shortcuts

```ruby
RouteExtract.configure do |config|
  config.models_only      # Extract only models
  config.views_only       # Extract only views
  config.controllers_only # Extract only controllers
  config.mv_mode          # Extract models and views
  config.mc_mode          # Extract models and controllers
  config.vc_mode          # Extract views and controllers
  config.mvc_mode         # Extract models, views, and controllers (default)
end
```



## Command Line Interface

RouteExtract provides a comprehensive CLI built with Thor. All commands support various options and flags.

### Basic Commands

#### Extract Route

```bash
route_extract extract ROUTE_PATTERN [OPTIONS]
```

**Options:**
- `--mode MODE`: Extraction mode (mvc, m, v, c, mv, mc, vc)
- `--output PATH`: Custom output directory
- `--include-gems`: Include gem source files (default: true)
- `--include-tests`: Include test files (default: false)
- `--compress`: Compress extract into archive
- `--verbose`: Enable verbose output

**Examples:**
```bash
# Basic extraction
route_extract extract "users#index"

# Extract only models and views
route_extract extract "users#show" --mode mv

# Extract with custom output directory
route_extract extract "posts#create" --output /tmp/extracts

# Extract with compression
route_extract extract "admin/users#index" --compress

# Extract with tests included
route_extract extract "api/v1/users#show" --include-tests --verbose
```

#### Extract Multiple Routes

```bash
route_extract extract_multiple PATTERN1,PATTERN2,... [OPTIONS]
```

**Examples:**
```bash
# Extract multiple specific routes
route_extract extract_multiple "users#index,users#show,users#create"

# Extract with specific mode for all
route_extract extract_multiple "posts#index,posts#show" --mode vc
```

#### List Routes

```bash
route_extract list [OPTIONS]
```

**Options:**
- `--filter PATTERN`: Filter routes by pattern
- `--format FORMAT`: Output format (table, json, csv)

**Examples:**
```bash
# List all routes
route_extract list

# Filter routes containing 'admin'
route_extract list --filter admin

# Output as JSON
route_extract list --format json

# Filter and output as CSV
route_extract list --filter users --format csv
```

#### Route Information

```bash
route_extract info ROUTE_PATTERN
```

**Examples:**
```bash
# Get detailed information about a route
route_extract info "users#index"

# Get information with verbose output
route_extract info "admin/posts#show" --verbose
```

#### Cleanup

```bash
route_extract cleanup [OPTIONS]
```

**Options:**
- `--older-than DURATION`: Remove extracts older than specified time
- `--force`: Skip confirmation prompts

**Examples:**
```bash
# Interactive cleanup
route_extract cleanup

# Remove extracts older than 7 days
route_extract cleanup --older-than 7d

# Force cleanup without confirmation
route_extract cleanup --older-than 1w --force
```

### Global Options

All commands support these global options:

- `--verbose`: Enable verbose output
- `--rails-root PATH`: Specify Rails application root directory

### Help

Get help for any command:

```bash
# General help
route_extract help

# Help for specific command
route_extract help extract
route_extract help list
```

## Rake Tasks

RouteExtract provides comprehensive rake tasks for integration with Rails applications and CI/CD pipelines.

### Basic Extraction Tasks

#### Extract Single Route

```bash
rake route_extract:extract[route_pattern,mode]
```

**Environment Variables:**
- `VERBOSE=true`: Enable verbose output
- `MODE=mvc`: Extraction mode
- `INCLUDE_GEMS=false`: Include gem source files
- `INCLUDE_TESTS=true`: Include test files
- `COMPRESS=true`: Compress extracts

**Examples:**
```bash
# Basic extraction
rake route_extract:extract[users#index]

# Extract with specific mode
rake route_extract:extract[users#show,mv]

# Extract with environment variables
VERBOSE=true MODE=mvc rake route_extract:extract[posts#create]

# Extract with all options
VERBOSE=true INCLUDE_TESTS=true COMPRESS=true rake route_extract:extract[admin/users#index]
```

#### Extract Multiple Routes

```bash
rake route_extract:extract_multiple[route1,route2,route3]
```

**Examples:**
```bash
# Extract multiple routes
rake route_extract:extract_multiple[users#index,users#show,posts#index]

# With environment variables
MODE=vc COMPRESS=true rake route_extract:extract_multiple[api/v1/users#index,api/v1/users#show]
```

#### Extract by Pattern

```bash
rake route_extract:extract_pattern[pattern]
```

**Examples:**
```bash
# Extract all routes containing 'users'
rake route_extract:extract_pattern[users]

# Extract all admin routes
rake route_extract:extract_pattern[admin]
```

#### Extract Controller Routes

```bash
rake route_extract:extract_controller[controller_name]
```

**Examples:**
```bash
# Extract all routes for users controller
rake route_extract:extract_controller[users]

# Extract all routes for admin/posts controller
rake route_extract:extract_controller[admin/posts]
```

### Route Information Tasks

#### List Routes

```bash
rake route_extract:list
```

**Environment Variables:**
- `FILTER=pattern`: Filter routes by pattern
- `FORMAT=table`: Output format (table, json, csv)

**Examples:**
```bash
# List all routes
rake route_extract:list

# Filter routes
FILTER=admin rake route_extract:list

# Output as JSON
FORMAT=json rake route_extract:list
```

#### Route Information

```bash
rake route_extract:info[route_pattern]
```

**Examples:**
```bash
# Get route information
rake route_extract:info[users#index]

# With verbose output
VERBOSE=true rake route_extract:info[admin/posts#show]
```

#### Find Routes

```bash
rake route_extract:find[pattern]
```

**Examples:**
```bash
# Find routes matching pattern
rake route_extract:find[users]

# Find API routes
rake route_extract:find[api]
```

#### Controller Routes

```bash
rake route_extract:controller[controller_name]
```

**Examples:**
```bash
# Show routes for specific controller
rake route_extract:controller[users]

# Show routes for namespaced controller
rake route_extract:controller[admin/posts]
```

#### Validate Routes

```bash
rake route_extract:validate[route1,route2,route3]
```

**Examples:**
```bash
# Validate specific routes
rake route_extract:validate[users#index,users#show,posts#index]
```

#### Route Statistics

```bash
rake route_extract:route_stats
```

### Management Tasks

#### List Extracts

```bash
rake route_extract:list_extracts
```

#### Extraction Statistics

```bash
rake route_extract:stats
```

#### Cleanup Tasks

```bash
# Interactive cleanup
rake route_extract:cleanup

# Remove extracts older than specified time
rake route_extract:cleanup_old[7d]

# Keep only N most recent extracts
rake route_extract:cleanup_keep[5]

# Remove all extracts (dangerous!)
rake route_extract:cleanup_all

# Validate existing extracts
rake route_extract:validate_extracts

# Remove invalid extracts
rake route_extract:cleanup_invalid
```

**Environment Variables for Cleanup:**
- `FORCE=true`: Skip confirmation prompts
- `VERBOSE=true`: Enable verbose output
- `OLDER_THAN=7d`: Duration for cleanup_old
- `KEEP_LATEST=5`: Count for cleanup_keep

### Help Tasks

```bash
# General help
rake route_extract:help

# Cleanup help
rake route_extract:cleanup_help
```

## Ruby API

RouteExtract provides a comprehensive Ruby API for programmatic access to all functionality.

### Basic Usage

```ruby
require 'route_extract'

# Configure the gem
RouteExtract.configure do |config|
  config.verbose = true
  config.include_gems = true
end

# Extract a single route
result = RouteExtract.extract_route("users#index")

if result[:success]
  puts "Extracted to: #{result[:extract_path]}"
  puts "Files: #{result[:files_count]}"
else
  puts "Error: #{result[:error]}"
end
```

### Advanced API Usage

#### Extract Manager

```ruby
# Create an extract manager
manager = RouteExtract::ExtractManager.new(RouteExtract.config)

# Extract single route with options
result = manager.extract_route("users#show", {
  mode: "mvc",
  include_gems: true,
  include_tests: false,
  compress: false
})

# Extract multiple routes
results = manager.extract_routes([
  "users#index",
  "users#show",
  "posts#index"
], { mode: "mv" })

# Extract routes by pattern
result = manager.extract_routes_by_pattern("admin", { mode: "mvc" })

# Extract controller routes
result = manager.extract_controller_routes("users", { mode: "vc" })

# Get extraction statistics
stats = manager.extraction_statistics
puts "Total extracts: #{stats[:extracts_count]}"
puts "Total size: #{stats[:total_size]}"

# List existing extracts
extracts = manager.list_extracts
extracts.each do |extract|
  puts "#{extract[:name]}: #{extract[:route]['controller']}##{extract[:route]['action']}"
end

# Cleanup extracts
result = manager.cleanup_extracts({
  older_than: "7d",
  force: false
})
```

#### Route Analyzer

```ruby
# Create a route analyzer
analyzer = RouteExtract::RouteAnalyzer.new(RouteExtract.config)

# List all routes
routes = analyzer.list_routes
routes.each do |route|
  puts "#{route[:controller]}##{route[:action]} (#{route[:method]})"
end

# Get route information
info = analyzer.route_info("users#index")
puts "Pattern: #{info[:pattern]}"
puts "Files: #{info[:files].keys.join(', ')}"

# Find routes by pattern
matching_routes = analyzer.find_routes_by_pattern("admin")

# Check if route exists
exists = analyzer.route_exists?("users#index")

# Get route dependencies
dependencies = analyzer.route_dependencies("users#show")
puts "Models: #{dependencies[:models].join(', ')}"
puts "Gems: #{dependencies[:gems].join(', ')}"
```

#### Gem Analyzer

```ruby
# Create a gem analyzer
gem_analyzer = RouteExtract::GemAnalyzer.new(RouteExtract.config)

# Analyze all bundle gems
gems_info = gem_analyzer.analyze_bundle_gems
gems_info.each do |name, info|
  puts "#{name} (#{info[:version]}): #{info[:summary]}"
end

# Analyze specific gem
gem_info = gem_analyzer.analyze_gem("devise")
puts "Devise version: #{gem_info[:version]}"
puts "Files: #{gem_info[:lib_files].count}"

# Extract gem dependencies for files
file_paths = [
  "app/controllers/users_controller.rb",
  "app/models/user.rb"
]
dependencies = gem_analyzer.extract_gem_dependencies(file_paths)

# Extract gem files
result = gem_analyzer.extract_gem_files("devise", "/tmp/gem_extracts")
if result[:success]
  puts "Extracted #{result[:extracted_files].count} files"
end

# Create dependency graph
graph = gem_analyzer.create_gem_dependency_graph
graph.each do |gem_name, info|
  puts "#{gem_name}: depends on #{info[:dependencies].join(', ')}"
end
```

#### File Analyzer

```ruby
# Create a file analyzer
file_analyzer = RouteExtract::FileAnalyzer.new(RouteExtract.config)

# Analyze single file
analysis = file_analyzer.analyze_file("app/controllers/users_controller.rb")
puts "Complexity: #{analysis[:complexity][:cyclomatic]}"
puts "Dependencies: #{analysis[:dependencies][:gems].join(', ')}"

# Analyze multiple files
file_paths = [
  "app/controllers/users_controller.rb",
  "app/models/user.rb",
  "app/views/users/index.html.erb"
]
results = file_analyzer.analyze_files(file_paths)
puts "Total files: #{results[:summary][:total_files]}"
puts "Total lines: #{results[:summary][:total_lines]}"

# Create dependency matrix
matrix = file_analyzer.create_dependency_matrix(file_paths)
matrix.each do |file, deps|
  puts "#{file} depends on: #{deps[:depends_on].join(', ')}"
end

# Get optimization suggestions
suggestions = file_analyzer.suggest_optimizations(results)
suggestions[:complexity].each do |suggestion|
  puts "#{suggestion[:file]}: #{suggestion[:issue]} - #{suggestion[:suggestion]}"
end
```

### Error Handling

```ruby
begin
  result = RouteExtract.extract_route("nonexistent#route")
rescue RouteExtract::Error => e
  puts "RouteExtract error: #{e.message}"
rescue => e
  puts "Unexpected error: #{e.message}"
end

# Check result success
result = RouteExtract.extract_route("users#index")
if result[:success]
  # Handle success
  puts "Success: #{result[:extract_path]}"
else
  # Handle failure
  puts "Failed: #{result[:error]}"
  puts result[:backtrace].join("\n") if result[:backtrace]
end
```


## Extraction Modes

RouteExtract supports several extraction modes to give you precise control over what code is extracted.

### Available Modes

| Mode | Description | Includes |
|------|-------------|----------|
| `m` or `models` | Models only | Model files, concerns, associations |
| `v` or `views` | Views only | View templates, partials, layouts, helpers |
| `c` or `controllers` | Controllers only | Controller files, concerns, filters |
| `mv` or `models_views` | Models and Views | Models + Views (no controllers) |
| `mc` or `models_controllers` | Models and Controllers | Models + Controllers (no views) |
| `vc` or `views_controllers` | Views and Controllers | Views + Controllers (no models) |
| `mvc` or `all` | Full MVC (default) | Models + Views + Controllers |

### Mode Examples

#### Models Only (`m`)
```bash
route_extract extract "users#index" --mode m
```
Extracts:
- `app/models/user.rb`
- `app/models/concerns/user_concerns.rb`
- Associated model files

#### Views Only (`v`)
```bash
route_extract extract "users#index" --mode v
```
Extracts:
- `app/views/users/index.html.erb`
- `app/views/users/_user.html.erb` (partials)
- `app/views/layouts/application.html.erb`
- `app/helpers/users_helper.rb`

#### Controllers Only (`c`)
```bash
route_extract extract "users#index" --mode c
```
Extracts:
- `app/controllers/users_controller.rb`
- `app/controllers/application_controller.rb`
- `app/controllers/concerns/authentication.rb`

#### Models and Views (`mv`)
```bash
route_extract extract "users#show" --mode mv
```
Extracts:
- All model files
- All view files
- No controller files

### Choosing the Right Mode

- **Use `m`** when analyzing data models and business logic
- **Use `v`** when working on UI/UX or frontend concerns
- **Use `c`** when focusing on request handling and business logic flow
- **Use `mv`** when working on data presentation without controller logic
- **Use `mc`** when analyzing backend logic without UI concerns
- **Use `vc`** when working on user interaction without data model changes
- **Use `mvc`** for complete feature analysis or migration

## Output Structure

RouteExtract creates a well-organized directory structure for each extraction.

### Directory Layout

```
route_extracts/
├── users_index_20231127_143022/          # Route extraction directory
│   ├── models/                           # Model files
│   │   ├── user.rb
│   │   ├── profile.rb
│   │   └── concerns/
│   │       └── authenticatable.rb
│   ├── views/                            # View files
│   │   ├── users/
│   │   │   ├── index.html.erb
│   │   │   └── _user.html.erb
│   │   ├── layouts/
│   │   │   └── application.html.erb
│   │   └── helpers/
│   │       └── users_helper.rb
│   ├── controllers/                      # Controller files
│   │   ├── users_controller.rb
│   │   ├── application_controller.rb
│   │   └── concerns/
│   │       └── authentication.rb
│   ├── gems/                            # Gem source files
│   │   ├── devise/
│   │   │   └── lib/
│   │   └── kaminari/
│   │       └── lib/
│   ├── tests/                           # Test files (if enabled)
│   │   ├── spec/
│   │   └── features/
│   └── manifest.json                    # Extraction manifest
└── posts_show_20231127_143045/          # Another extraction
    └── ...
```

### Naming Convention

Extract directories follow this naming pattern:
```
{controller}_{action}_{timestamp}/
```

Examples:
- `users_index_20231127_143022/`
- `admin_posts_show_20231127_143045/`
- `api_v1_users_create_20231127_143100/`

### Manifest File

Each extraction includes a `manifest.json` file with metadata:

```json
{
  "route_extract": {
    "version": "0.1.0",
    "generated_at": "2023-11-27T14:30:22Z",
    "route": {
      "pattern": "users",
      "controller": "users",
      "action": "index",
      "method": "GET",
      "name": "users",
      "helper": "users_path"
    },
    "extraction": {
      "mode": "mvc",
      "include_models": true,
      "include_views": true,
      "include_controllers": true,
      "include_gems": true,
      "include_tests": false
    },
    "files": {
      "count": 15,
      "list": [
        "models/user.rb",
        "views/users/index.html.erb",
        "controllers/users_controller.rb"
      ]
    },
    "statistics": {
      "total_size": "45.2 KB",
      "file_types": {
        "rb": 8,
        "erb": 4,
        "md": 2,
        "txt": 1
      }
    }
  }
}
```

### File Organization

#### Models Directory
- Main model files
- Model concerns in `concerns/` subdirectory
- Associated models (through relationships)

#### Views Directory
- Controller-specific views in subdirectories
- Shared partials
- Layout files in `layouts/` subdirectory
- Helper files in `helpers/` subdirectory

#### Controllers Directory
- Main controller file
- Application controller (if referenced)
- Controller concerns in `concerns/` subdirectory

#### Gems Directory
- Essential gem source files organized by gem name
- Only includes relevant files (lib/, README, LICENSE, etc.)
- Maintains original directory structure within each gem

#### Tests Directory (if enabled)
- RSpec specs in `spec/` subdirectory
- Cucumber features in `features/` subdirectory
- Test helpers and support files

## Advanced Usage

### Custom Configuration

#### Environment-Specific Configuration

```ruby
# config/environments/development.rb
Rails.application.configure do
  config.after_initialize do
    RouteExtract.configure do |config|
      config.verbose = true
      config.include_tests = true
    end
  end
end

# config/environments/production.rb
Rails.application.configure do
  config.after_initialize do
    RouteExtract.configure do |config|
      config.verbose = false
      config.include_tests = false
      config.compress_extracts = true
    end
  end
end
```

#### Custom Exclusion Patterns

```ruby
RouteExtract.configure do |config|
  config.exclude_patterns += %w[
    vendor/custom
    lib/legacy
    app/models/deprecated
    *.backup
    *.tmp
  ]
end
```

#### Custom Gem Paths

```ruby
RouteExtract.configure do |config|
  config.gem_source_paths = [
    "/usr/local/custom_gems",
    "#{Rails.root}/vendor/gems"
  ]
end
```

### Batch Operations

#### Extract All Controller Routes

```ruby
# Extract all routes for multiple controllers
controllers = %w[users posts comments admin/users]
controllers.each do |controller|
  manager = RouteExtract::ExtractManager.new(RouteExtract.config)
  result = manager.extract_controller_routes(controller)
  puts "#{controller}: #{result[:success] ? 'Success' : result[:error]}"
end
```

#### Extract by Route Patterns

```ruby
# Extract all API routes
patterns = ["api/v1", "api/v2"]
patterns.each do |pattern|
  manager = RouteExtract::ExtractManager.new(RouteExtract.config)
  result = manager.extract_routes_by_pattern(pattern)
  puts "#{pattern}: #{result[:successful_count]} routes extracted"
end
```

### Integration with CI/CD

#### GitHub Actions Example

```yaml
name: Route Analysis
on:
  pull_request:
    paths:
      - 'app/controllers/**'
      - 'app/models/**'
      - 'app/views/**'

jobs:
  analyze_routes:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Extract changed routes
        run: |
          # Extract routes for changed controllers
          git diff --name-only HEAD~1 | grep 'app/controllers' | \
          sed 's/app\/controllers\///; s/_controller\.rb//; s/\//\#/' | \
          xargs -I {} rake route_extract:extract[{}]
      - name: Upload extracts
        uses: actions/upload-artifact@v2
        with:
          name: route-extracts
          path: route_extracts/
```

#### Jenkins Pipeline Example

```groovy
pipeline {
    agent any
    stages {
        stage('Extract Routes') {
            steps {
                script {
                    def routes = ['users#index', 'posts#show', 'admin/users#index']
                    routes.each { route ->
                        sh "rake route_extract:extract[${route}]"
                    }
                }
            }
        }
        stage('Archive Extracts') {
            steps {
                archiveArtifacts artifacts: 'route_extracts/**/*', fingerprint: true
            }
        }
    }
}
```

### Custom Analysis

#### Dependency Analysis

```ruby
# Analyze gem dependencies across multiple routes
routes = ['users#index', 'posts#show', 'admin/dashboard#index']
all_dependencies = {}

routes.each do |route|
  analyzer = RouteExtract::RouteAnalyzer.new(RouteExtract.config)
  dependencies = analyzer.route_dependencies(route)
  
  dependencies[:gems].each do |gem|
    all_dependencies[gem] ||= []
    all_dependencies[gem] << route
  end
end

# Find most common dependencies
common_gems = all_dependencies.sort_by { |_, routes| -routes.length }
puts "Most common gem dependencies:"
common_gems.first(10).each do |gem, routes|
  puts "#{gem}: used by #{routes.length} routes"
end
```

#### Complexity Analysis

```ruby
# Analyze complexity of extracted files
extracts_dir = RouteExtract.config.full_extract_path
Dir.glob(File.join(extracts_dir, '*')).each do |extract_path|
  next unless File.directory?(extract_path)
  
  manifest_path = File.join(extract_path, 'manifest.json')
  next unless File.exist?(manifest_path)
  
  manifest = JSON.parse(File.read(manifest_path))
  route = "#{manifest['route_extract']['route']['controller']}##{manifest['route_extract']['route']['action']}"
  
  # Analyze all Ruby files in the extract
  ruby_files = Dir.glob(File.join(extract_path, '**', '*.rb'))
  
  file_analyzer = RouteExtract::FileAnalyzer.new(RouteExtract.config)
  analysis = file_analyzer.analyze_files(ruby_files)
  
  puts "#{route}:"
  puts "  Files: #{analysis[:summary][:total_files]}"
  puts "  Lines: #{analysis[:summary][:total_lines]}"
  puts "  Complexity distribution: #{analysis[:summary][:complexity_distribution]}"
end
```

## Troubleshooting

### Common Issues

#### Route Not Found

**Problem:** `Route not found: users#index`

**Solutions:**
1. Check route exists: `rake route_extract:list | grep users`
2. Verify route pattern: `rake route_extract:info[users#index]`
3. Check for typos in controller/action names
4. Ensure you're in the Rails application root directory

#### Permission Denied

**Problem:** `Permission denied when creating extract directory`

**Solutions:**
1. Check directory permissions: `ls -la route_extracts/`
2. Ensure Rails app has write permissions to extract directory
3. Try custom output directory: `--output /tmp/extracts`

#### Missing Dependencies

**Problem:** `Gem not found: some_gem`

**Solutions:**
1. Check Gemfile includes the gem: `bundle list | grep some_gem`
2. Run `bundle install` to ensure all gems are installed
3. Check gem is available in current environment
4. Disable gem extraction: `--no-include-gems`

#### Large Extract Size

**Problem:** Extract directories are very large

**Solutions:**
1. Use specific extraction modes: `--mode c` instead of `mvc`
2. Disable gem extraction: `--no-include-gems`
3. Enable compression: `--compress`
4. Add exclusion patterns in configuration

#### Rails Environment Issues

**Problem:** `Rails application not found`

**Solutions:**
1. Ensure you're in Rails application root directory
2. Check `config/application.rb` exists
3. Set Rails root explicitly: `--rails-root /path/to/app`
4. Ensure Rails environment is properly loaded

### Debug Mode

Enable verbose output for detailed debugging:

```bash
# CLI
route_extract extract "users#index" --verbose

# Rake task
VERBOSE=true rake route_extract:extract[users#index]

# Ruby API
RouteExtract.configure { |config| config.verbose = true }
```

### Log Analysis

Check Rails logs for additional information:

```bash
# Development log
tail -f log/development.log

# Check for RouteExtract-related entries
grep -i "route.*extract" log/development.log
```

### Validation

Validate existing extracts:

```bash
# Check all extracts
rake route_extract:validate_extracts

# Clean up invalid extracts
rake route_extract:cleanup_invalid FORCE=true
```

## Best Practices

### Configuration Management

1. **Use Environment-Specific Settings**
   ```ruby
   # Different settings for development vs production
   config.verbose = Rails.env.development?
   config.include_tests = Rails.env.development?
   ```

2. **Organize Exclusion Patterns**
   ```ruby
   # Group related patterns
   config.exclude_patterns += %w[
     # Temporary files
     *.tmp *.backup *.swp
     
     # Legacy code
     lib/legacy app/models/deprecated
     
     # Third-party
     vendor/custom
   ]
   ```

3. **Document Custom Configuration**
   ```ruby
   # config/initializers/route_extract.rb
   RouteExtract.configure do |config|
     # Custom setting for our application's specific needs
     # We exclude these patterns because...
     config.exclude_patterns += %w[app/models/legacy]
   end
   ```

### Extraction Strategies

1. **Start Small**
   - Begin with single routes using specific modes
   - Gradually expand to full MVC extraction
   - Use compression for large extracts

2. **Use Appropriate Modes**
   - `c` mode for API endpoints (no views needed)
   - `v` mode for frontend-only changes
   - `mvc` mode for complete feature analysis

3. **Batch Operations**
   - Group related routes for batch extraction
   - Use patterns to extract entire controllers
   - Schedule regular extractions for monitoring

### Performance Optimization

1. **Limit Scope**
   ```ruby
   # Extract only what you need
   config.include_gems = false  # Skip gems if not needed
   config.max_depth = 3         # Limit dependency depth
   ```

2. **Use Exclusion Patterns**
   ```ruby
   # Exclude large, irrelevant directories
   config.exclude_patterns += %w[
     public/assets
     node_modules
     vendor/bundle
   ]
   ```

3. **Compress Large Extracts**
   ```ruby
   # Enable compression for storage efficiency
   config.compress_extracts = true
   ```

### Maintenance

1. **Regular Cleanup**
   ```bash
   # Weekly cleanup of old extracts
   rake route_extract:cleanup_old[7d] FORCE=true
   
   # Keep only recent extracts
   rake route_extract:cleanup_keep[10] FORCE=true
   ```

2. **Monitor Extract Size**
   ```bash
   # Check extraction statistics
   rake route_extract:stats
   
   # Validate extract integrity
   rake route_extract:validate_extracts
   ```

3. **Version Control**
   ```gitignore
   # .gitignore
   route_extracts/
   *.route_extract.tar.gz
   ```

### Team Collaboration

1. **Standardize Configuration**
   - Use consistent settings across team
   - Document custom configurations
   - Share extraction patterns

2. **CI/CD Integration**
   - Automate extraction for code reviews
   - Archive extracts as build artifacts
   - Use for documentation generation

3. **Documentation**
   - Document extraction procedures
   - Share useful extraction patterns
   - Maintain extraction guidelines

### Security Considerations

1. **Sensitive Data**
   ```ruby
   # Exclude files with sensitive information
   config.exclude_patterns += %w[
     config/database.yml
     config/secrets.yml
     config/master.key
     .env
   ]
   ```

2. **Gem Source Files**
   - Review gem extracts for sensitive information
   - Consider disabling gem extraction in production
   - Use compression to protect extracted content

3. **Access Control**
   - Restrict access to extract directories
   - Use appropriate file permissions
   - Consider encryption for sensitive extracts

This completes the comprehensive RouteExtract User Guide. The gem provides powerful capabilities for extracting and analyzing Rails application code, with flexible configuration options and multiple interfaces to suit different workflows and use cases.

