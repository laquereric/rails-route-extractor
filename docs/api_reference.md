# RouteExtract API Reference

## Table of Contents

1. [Module Methods](#module-methods)
2. [Configuration](#configuration)
3. [ExtractManager](#extractmanager)
4. [RouteAnalyzer](#routeanalyzer)
5. [GemAnalyzer](#gemanalyzer)
6. [FileAnalyzer](#fileanalyzer)
7. [DependencyTracker](#dependencytracker)
8. [CodeExtractor](#codeextractor)
9. [Error Classes](#error-classes)
10. [Data Structures](#data-structures)

## Module Methods

### RouteExtract.configure

Configure the RouteExtract gem with a block.

```ruby
RouteExtract.configure do |config|
  config.verbose = true
  config.include_gems = false
end
```

**Parameters:**
- Block that yields a Configuration object

**Returns:** Configuration object

### RouteExtract.extract_route

Extract code for a single route.

```ruby
result = RouteExtract.extract_route("users#index", options = {})
```

**Parameters:**
- `route_pattern` (String): Route pattern in format "controller#action"
- `options` (Hash): Extraction options
  - `:mode` (String): Extraction mode ('mvc', 'm', 'v', 'c', etc.)
  - `:include_gems` (Boolean): Include gem source files
  - `:include_tests` (Boolean): Include test files
  - `:compress` (Boolean): Compress the extract

**Returns:** Hash with extraction result
- `:success` (Boolean): Whether extraction succeeded
- `:extract_path` (String): Path to extracted files (if successful)
- `:files_count` (Integer): Number of files extracted
- `:total_size` (String): Human-readable total size
- `:error` (String): Error message (if failed)

### RouteExtract.extract_routes

Extract code for multiple routes.

```ruby
result = RouteExtract.extract_routes(["users#index", "posts#show"], options = {})
```

**Parameters:**
- `route_patterns` (Array<String>): Array of route patterns
- `options` (Hash): Extraction options (same as extract_route)

**Returns:** Hash with batch extraction result
- `:success` (Boolean): Whether all extractions succeeded
- `:successful_count` (Integer): Number of successful extractions
- `:failed_count` (Integer): Number of failed extractions
- `:total_files` (Integer): Total files extracted
- `:total_size` (String): Human-readable total size
- `:results` (Array<Hash>): Individual extraction results

### RouteExtract.list_routes

List all available routes in the application.

```ruby
routes = RouteExtract.list_routes
```

**Returns:** Array of route hashes
- `:pattern` (String): Route pattern
- `:controller` (String): Controller name
- `:action` (String): Action name
- `:method` (String): HTTP method
- `:name` (String): Route name
- `:helper` (String): Route helper method name

### RouteExtract.route_info

Get detailed information about a specific route.

```ruby
info = RouteExtract.route_info("users#index")
```

**Parameters:**
- `route_pattern` (String): Route pattern in format "controller#action"

**Returns:** Hash with route information or nil if not found
- `:pattern` (String): Route pattern
- `:controller` (String): Controller name
- `:action` (String): Action name
- `:method` (String): HTTP method
- `:name` (String): Route name
- `:helper` (String): Route helper method name
- `:path` (String): Route path template
- `:files` (Hash): Associated files by type

### RouteExtract.cleanup_extracts

Clean up old extraction directories.

```ruby
result = RouteExtract.cleanup_extracts(options = {})
```

**Parameters:**
- `options` (Hash): Cleanup options
  - `:older_than` (String): Remove extracts older than duration (e.g., "7d")
  - `:keep_latest` (Integer): Keep only N most recent extracts
  - `:force` (Boolean): Skip confirmation prompts

**Returns:** Hash with cleanup result
- `:success` (Boolean): Whether cleanup succeeded
- `:removed_count` (Integer): Number of extracts removed
- `:space_freed` (String): Human-readable space freed
- `:error` (String): Error message (if failed)

## Configuration

### Configuration Options

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
  config.exclude_patterns = %w[tmp/ log/ public/assets]
  
  # Custom gem source paths
  config.gem_source_paths = []
end
```

### Configuration Methods

#### Mode Shortcuts

```ruby
config.models_only      # Extract only models
config.views_only       # Extract only views
config.controllers_only # Extract only controllers
config.mv_mode          # Extract models and views
config.mc_mode          # Extract models and controllers
config.vc_mode          # Extract views and controllers
config.mvc_mode         # Extract models, views, and controllers
```

#### Utility Methods

```ruby
config.rails_application?  # Check if in Rails application
config.full_extract_path   # Get absolute path to extract directory
```

## ExtractManager

Main class for managing route extractions.

### Constructor

```ruby
manager = RouteExtract::ExtractManager.new(config)
```

**Parameters:**
- `config` (Configuration): Configuration object

### Instance Methods

#### extract_route

Extract code for a single route.

```ruby
result = manager.extract_route(route_pattern, options = {})
```

#### extract_routes

Extract code for multiple routes.

```ruby
result = manager.extract_routes(route_patterns, options = {})
```

#### extract_routes_by_pattern

Extract all routes matching a pattern.

```ruby
result = manager.extract_routes_by_pattern(pattern, options = {})
```

#### extract_controller_routes

Extract all routes for a specific controller.

```ruby
result = manager.extract_controller_routes(controller_name, options = {})
```

#### extraction_statistics

Get statistics about existing extracts.

```ruby
stats = manager.extraction_statistics
```

**Returns:** Hash with statistics
- `:extracts_count` (Integer): Number of extract directories
- `:total_size` (String): Human-readable total size
- `:oldest` (DateTime): Oldest extract timestamp
- `:newest` (DateTime): Newest extract timestamp
- `:extract_paths` (Array<String>): Paths to extract directories

#### list_extracts

List all existing extract directories.

```ruby
extracts = manager.list_extracts
```

**Returns:** Array of extract information hashes
- `:path` (String): Full path to extract directory
- `:name` (String): Extract directory name
- `:size` (String): Human-readable size
- `:valid` (Boolean): Whether extract is valid
- `:route` (Hash): Route information (if valid)
- `:files_count` (Integer): Number of files (if valid)
- `:created_at` (DateTime): Creation timestamp (if valid)
- `:error` (String): Error message (if invalid)

#### cleanup_extracts

Clean up old extract directories.

```ruby
result = manager.cleanup_extracts(options = {})
```

#### validate_extract

Validate an existing extract directory.

```ruby
result = manager.validate_extract(extract_path)
```

**Returns:** Hash with validation result
- `:valid` (Boolean): Whether extract is valid
- `:error` (String): Error message (if invalid)
- `:manifest` (Hash): Parsed manifest (if valid)
- `:files_count` (Integer): Number of files (if valid)
- `:route` (Hash): Route information (if valid)

## RouteAnalyzer

Class for analyzing Rails routes.

### Constructor

```ruby
analyzer = RouteExtract::RouteAnalyzer.new(config)
```

### Instance Methods

#### list_routes

List all available routes.

```ruby
routes = analyzer.list_routes
```

#### route_info

Get information about a specific route.

```ruby
info = analyzer.route_info(route_pattern)
```

#### route_exists?

Check if a route exists.

```ruby
exists = analyzer.route_exists?(route_pattern)
```

**Returns:** Boolean

#### find_routes_by_pattern

Find routes matching a pattern.

```ruby
routes = analyzer.find_routes_by_pattern(pattern)
```

#### route_dependencies

Get dependencies for a route.

```ruby
dependencies = analyzer.route_dependencies(route_pattern)
```

**Returns:** Hash with dependency arrays
- `:models` (Array<String>): Model file paths
- `:views` (Array<String>): View file paths
- `:controllers` (Array<String>): Controller file paths
- `:helpers` (Array<String>): Helper file paths
- `:concerns` (Array<String>): Concern file paths
- `:gems` (Array<String>): Gem names

#### analyze_route_complexity

Analyze the complexity of a route.

```ruby
complexity = analyzer.analyze_route_complexity(route_pattern)
```

**Returns:** Hash with complexity metrics
- `:file_count` (Integer): Number of associated files
- `:total_lines` (Integer): Total lines of code
- `:dependency_depth` (Integer): Maximum dependency depth
- `:gem_dependencies` (Integer): Number of gem dependencies

## GemAnalyzer

Class for analyzing gem dependencies and usage.

### Constructor

```ruby
gem_analyzer = RouteExtract::GemAnalyzer.new(config)
```

### Instance Methods

#### analyze_bundle_gems

Analyze all gems in the current bundle.

```ruby
gems_info = gem_analyzer.analyze_bundle_gems
```

**Returns:** Hash mapping gem names to gem information

#### analyze_gem

Analyze a specific gem.

```ruby
gem_info = gem_analyzer.analyze_gem(gem_name)
```

**Returns:** Hash with gem information
- `:name` (String): Gem name
- `:version` (String): Gem version
- `:found` (Boolean): Whether gem was found
- `:gem_dir` (String): Gem directory path
- `:summary` (String): Gem summary
- `:description` (String): Gem description
- `:homepage` (String): Gem homepage URL
- `:authors` (Array<String>): Gem authors
- `:license` (String): Gem license
- `:dependencies` (Array<Hash>): Gem dependencies
- `:files` (Array<String>): Gem files
- `:lib_files` (Array<String>): Library files
- `:important_files` (Array<String>): Important files
- `:size` (Integer): Gem size in bytes

#### extract_gem_dependencies

Extract gem dependencies for a list of files.

```ruby
dependencies = gem_analyzer.extract_gem_dependencies(file_paths)
```

**Returns:** Hash mapping gem names to usage information
- `:files_using` (Array<String>): Files that use the gem
- `:gem_info` (Hash): Gem information

#### extract_gem_files

Extract essential files from a gem.

```ruby
result = gem_analyzer.extract_gem_files(gem_name, target_directory)
```

**Returns:** Hash with extraction result
- `:success` (Boolean): Whether extraction succeeded
- `:gem_name` (String): Gem name
- `:version` (String): Gem version
- `:extracted_files` (Array<String>): Paths to extracted files
- `:total_size` (Integer): Total size in bytes
- `:target_directory` (String): Target directory path
- `:error` (String): Error message (if failed)

#### create_gem_dependency_graph

Create a dependency graph of gems.

```ruby
graph = gem_analyzer.create_gem_dependency_graph
```

**Returns:** Hash mapping gem names to dependency information
- `:version` (String): Gem version
- `:dependencies` (Array<String>): Direct dependencies
- `:dependents` (Array<String>): Gems that depend on this gem

#### suggest_gems_for_files

Suggest gems that might be used by specific file types.

```ruby
suggestions = gem_analyzer.suggest_gems_for_files(file_paths)
```

**Returns:** Hash mapping suggestion categories to gem arrays

## FileAnalyzer

Class for analyzing individual files and code quality.

### Constructor

```ruby
file_analyzer = RouteExtract::FileAnalyzer.new(config)
```

### Instance Methods

#### analyze_file

Analyze a single file.

```ruby
analysis = file_analyzer.analyze_file(file_path)
```

**Returns:** Hash with file analysis
- `:path` (String): File path
- `:type` (Symbol): File type (:controller, :model, :view, etc.)
- `:size` (Integer): File size in bytes
- `:lines` (Hash): Line count analysis
- `:complexity` (Hash): Complexity metrics
- `:dependencies` (Hash): Dependency analysis
- `:patterns` (Hash): Design pattern analysis
- `:security` (Hash): Security issue analysis
- `:performance` (Hash): Performance issue analysis

#### analyze_files

Analyze multiple files.

```ruby
results = file_analyzer.analyze_files(file_paths)
```

**Returns:** Hash with comprehensive analysis
- `:files` (Array<Hash>): Individual file analyses
- `:summary` (Hash): Summary statistics

#### create_dependency_matrix

Create a dependency matrix showing relationships between files.

```ruby
matrix = file_analyzer.create_dependency_matrix(file_paths)
```

**Returns:** Hash mapping file paths to dependency information
- `:depends_on` (Array<String>): Files this file depends on
- `:depended_by` (Array<String>): Files that depend on this file

#### suggest_optimizations

Suggest optimizations based on analysis.

```ruby
suggestions = file_analyzer.suggest_optimizations(analysis_results)
```

**Returns:** Hash with suggestion categories
- `:complexity` (Array<Hash>): Complexity-related suggestions
- `:dependencies` (Array<Hash>): Dependency-related suggestions
- `:security` (Array<Hash>): Security-related suggestions
- `:performance` (Array<Hash>): Performance-related suggestions
- `:maintainability` (Array<Hash>): Maintainability suggestions

## DependencyTracker

Class for tracking code dependencies using CodeQL-like analysis.

### Constructor

```ruby
tracker = RouteExtract::DependencyTracker.new(config)
```

### Instance Methods

#### track_dependencies

Track dependencies for a set of files.

```ruby
dependencies = tracker.track_dependencies(file_paths)
```

#### find_related_files

Find files related to a specific file.

```ruby
related = tracker.find_related_files(file_path, max_depth = 3)
```

#### analyze_dependency_graph

Analyze the dependency graph for a set of files.

```ruby
graph = tracker.analyze_dependency_graph(file_paths)
```

## CodeExtractor

Class for extracting code files based on route analysis.

### Constructor

```ruby
extractor = RouteExtract::CodeExtractor.new(config)
```

### Instance Methods

#### extract_route

Extract files for a specific route.

```ruby
result = extractor.extract_route(route_pattern, options = {})
```

#### extract_routes

Extract files for multiple routes.

```ruby
result = extractor.extract_routes(route_patterns, options = {})
```

#### extract_files

Extract specific files to a target directory.

```ruby
result = extractor.extract_files(file_paths, target_directory, options = {})
```

## Error Classes

### RouteExtract::Error

Base error class for RouteExtract-specific errors.

```ruby
begin
  RouteExtract.extract_route("invalid#route")
rescue RouteExtract::Error => e
  puts "RouteExtract error: #{e.message}"
end
```

### RouteExtract::ConfigurationError

Raised when there are configuration-related errors.

### RouteExtract::ExtractionError

Raised when extraction operations fail.

### RouteExtract::AnalysisError

Raised when analysis operations fail.

## Data Structures

### Route Hash

```ruby
{
  pattern: "users#index",
  controller: "users",
  action: "index",
  method: "GET",
  name: "users",
  helper: "users_path",
  path: "/users"
}
```

### Extraction Result Hash

```ruby
{
  success: true,
  extract_path: "/path/to/extract",
  files_count: 15,
  total_size: "45.2 KB",
  route_pattern: "users#index",
  mode: "mvc",
  timestamp: "2023-11-27T14:30:22Z"
}
```

### File Analysis Hash

```ruby
{
  path: "/path/to/file.rb",
  type: :controller,
  size: 2048,
  lines: {
    total: 80,
    code: 65,
    comments: 10,
    blank: 5
  },
  complexity: {
    cyclomatic: 8,
    nesting_depth: 3,
    method_count: 5,
    class_count: 1,
    module_count: 0
  },
  dependencies: {
    requires: ["user", "application_controller"],
    includes: ["Authentication"],
    extends: ["ApplicationController"],
    gems: ["devise", "kaminari"],
    constants: ["User", "Post"]
  },
  patterns: {
    design_patterns: ["Observer"],
    rails_patterns: ["Callback", "Validation"],
    anti_patterns: []
  },
  security: {
    issues: [
      {
        type: "sql_injection",
        description: "Potential SQL injection vulnerability",
        suggestion: "Use parameterized queries"
      }
    ]
  },
  performance: {
    issues: [
      {
        type: "n_plus_one",
        description: "Potential N+1 query pattern",
        suggestion: "Use includes or joins"
      }
    ]
  }
}
```

This API reference provides comprehensive documentation for all public methods and classes in the RouteExtract gem. Use this reference when integrating RouteExtract into your applications or building custom tools on top of it.

