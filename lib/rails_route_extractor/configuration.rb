# frozen_string_literal: true

module RailsRouteExtractor
  class Configuration
    attr_accessor :extract_base_path,
                  :include_models,
                  :include_views,
                  :include_controllers,
                  :include_gems,
                  :include_tests,
                  :verbose,
                  :rails_root,
                  :exclude_patterns,
                  :gem_source_paths,
                  :max_depth,
                  :follow_associations,
                  :include_partials,
                  :include_helpers,
                  :include_concerns,
                  :compress_extracts,
                  :manifest_format

    def initialize
      @extract_base_path = "route_extracts"
      @include_models = true
      @include_views = true
      @include_controllers = true
      @include_gems = true
      @include_tests = false
      @verbose = false
      @rails_root = detect_rails_root
      @exclude_patterns = default_exclude_patterns
      @gem_source_paths = []
      @max_depth = 5
      @follow_associations = true
      @include_partials = true
      @include_helpers = true
      @include_concerns = true
      @compress_extracts = false
      @manifest_format = :json
    end

    # Extraction mode shortcuts
    def mvc_mode
      @include_models = true
      @include_views = true
      @include_controllers = true
    end

    def models_only
      @include_models = true
      @include_views = false
      @include_controllers = false
    end

    def views_only
      @include_models = false
      @include_views = true
      @include_controllers = false
    end

    def controllers_only
      @include_models = false
      @include_views = false
      @include_controllers = true
    end

    def mv_mode
      @include_models = true
      @include_views = true
      @include_controllers = false
    end

    def mc_mode
      @include_models = true
      @include_views = false
      @include_controllers = true
    end

    def vc_mode
      @include_models = false
      @include_views = true
      @include_controllers = true
    end

    # Get full extract path
    def full_extract_path
      if @rails_root
        File.join(@rails_root, @extract_base_path)
      else
        File.expand_path(@extract_base_path)
      end
    end

    # Check if we're in a Rails application
    def rails_application?
      @rails_root && File.exist?(File.join(@rails_root, "config", "application.rb"))
    end

    private

    def detect_rails_root
      if defined?(Rails) && Rails.respond_to?(:root)
        Rails.root.to_s
      elsif File.exist?("config/application.rb")
        Dir.pwd
      else
        current_dir = Dir.pwd
        while current_dir != "/"
          if File.exist?(File.join(current_dir, "config", "application.rb"))
            return current_dir
          end
          current_dir = File.dirname(current_dir)
        end
        nil
      end
    end

    def default_exclude_patterns
      %w[
        .git
        .svn
        .hg
        node_modules
        vendor/bundle
        tmp
        log
        coverage
        .bundle
        public/assets
        public/packs
        storage
        .sass-cache
        .yardoc
        doc/
        pkg/
        spec/dummy
        test/dummy
      ]
    end
  end
end

