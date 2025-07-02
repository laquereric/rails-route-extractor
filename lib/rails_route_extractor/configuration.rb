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

    def apply_mode(mode_str)
      return unless mode_str.is_a?(String)

      modes = mode_str.chars.uniq
      self.include_models = modes.include?('m')
      self.include_views = modes.include?('v')
      self.include_controllers = modes.include?('c')
    end

    def current_mode
      modes = []
      modes << 'm' if include_models
      modes << 'v' if include_views
      modes << 'c' if include_controllers

      mode_str = modes.sort.join

      is_custom_extra = include_helpers || include_partials || include_concerns

      if is_custom_extra
        return 'custom' if modes.any?
        return 'custom' # for helpers/partials/concerns only
      end

      known_modes = %w[m v c mc mv vc mvc]
      if known_modes.include?(mode_str)
        mode_str
      elsif modes.any?
        'custom'
      else
        'none'
      end
    end

    # Extraction mode shortcuts
    def mvc_mode
      set_mode(m: true, v: true, c: true)
    end

    def models_only
      set_mode(m: true)
    end

    def views_only
      set_mode(v: true)
    end

    def controllers_only
      set_mode(c: true)
    end

    def mv_mode
      set_mode(m: true, v: true)
    end

    def mc_mode
      set_mode(m: true, c: true)
    end

    def vc_mode
      set_mode(v: true, c: true)
    end

    # Get full extract path
    def full_extract_path
      base = rails_application? ? detect_rails_root : Dir.pwd
      File.join(base.to_s, @extract_base_path)
    end

    # Check if we're in a Rails application
    def rails_application?
      !!(detect_rails_root && File.exist?(File.join(detect_rails_root, "config", "application.rb")))
    end

    def set_mode(m: false, v: false, c: false)
      self.include_models = m
      self.include_views = v
      self.include_controllers = c
      # Also reset other flags for a clean mode
      self.include_gems = false
      self.include_tests = false
      self.include_partials = false
      self.include_helpers = false
      self.include_concerns = false
    end

    private

    def detect_rails_root
      if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
        Rails.root.to_s
      else
        # In a non-Rails environment, we can't reliably find a root.
        # We'll default to the current working directory for path expansion,
        # but @rails_root remains nil to indicate it's not a Rails app.
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

