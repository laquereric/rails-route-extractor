# RouteExtract Configuration
# 
# This file contains the configuration for the RouteExtract gem.
# Customize these settings to match your application's needs.

RouteExtract.configure do |config|
  # Base path for extracts (relative to Rails.root)
  # Default: "route_extracts"
  config.extract_base_path = "route_extracts"
  
  # What to include in extracts by default
  config.include_models = true
  config.include_views = true
  config.include_controllers = true
  config.include_gems = true
  config.include_tests = false
  
  # Analysis options
  config.max_depth = 5                    # Maximum dependency depth to follow
  config.follow_associations = true       # Follow ActiveRecord associations
  config.include_partials = true          # Include view partials
  config.include_helpers = true           # Include helper files
  config.include_concerns = true          # Include concerns
  
  # Output options
  config.verbose = false                  # Enable verbose output
  config.compress_extracts = false        # Compress extracts into archives
  config.manifest_format = :json          # Manifest format (:json, :yaml)
  
  # Additional exclusion patterns (added to defaults)
  # config.exclude_patterns += %w[
  #   custom_exclude_pattern
  #   another_pattern
  # ]
  
  # Custom gem source paths (if gems are installed in non-standard locations)
  # config.gem_source_paths = [
  #   "/custom/gem/path"
  # ]
end

# You can also set extraction mode shortcuts:
# RouteExtract.configure do |config|
#   config.models_only      # Extract only models
#   config.views_only       # Extract only views
#   config.controllers_only # Extract only controllers
#   config.mv_mode          # Extract models and views
#   config.mc_mode          # Extract models and controllers
#   config.vc_mode          # Extract views and controllers
#   config.mvc_mode         # Extract models, views, and controllers (default)
# end

