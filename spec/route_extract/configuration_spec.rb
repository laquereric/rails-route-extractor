# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RouteExtract::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.extract_base_path).to eq("route_extracts")
      expect(config.include_models).to be true
      expect(config.include_views).to be true
      expect(config.include_controllers).to be true
      expect(config.include_gems).to be true
      expect(config.include_tests).to be false
      expect(config.verbose).to be false
      expect(config.compress_extracts).to be false
      expect(config.max_depth).to eq(5)
      expect(config.follow_associations).to be true
      expect(config.include_partials).to be true
      expect(config.include_helpers).to be true
      expect(config.include_concerns).to be true
      expect(config.manifest_format).to eq(:json)
      expect(config.exclude_patterns).to be_an(Array)
      expect(config.gem_source_paths).to be_an(Array)
    end
  end

  describe "attribute accessors" do
    it "allows setting and getting extract_base_path" do
      config.extract_base_path = "custom_extracts"
      expect(config.extract_base_path).to eq("custom_extracts")
    end

    it "allows setting and getting boolean flags" do
      config.verbose = true
      config.include_gems = false
      config.compress_extracts = true

      expect(config.verbose).to be true
      expect(config.include_gems).to be false
      expect(config.compress_extracts).to be true
    end

    it "allows setting and getting numeric values" do
      config.max_depth = 10
      expect(config.max_depth).to eq(10)
    end

    it "allows setting and getting arrays" do
      config.exclude_patterns = %w[custom pattern]
      config.gem_source_paths = ["/custom/path"]

      expect(config.exclude_patterns).to eq(%w[custom pattern])
      expect(config.gem_source_paths).to eq(["/custom/path"])
    end
  end

  describe "mode shortcuts" do
    describe "#models_only" do
      it "sets extraction to models only" do
        config.models_only
        
        expect(config.include_models).to be true
        expect(config.include_views).to be false
        expect(config.include_controllers).to be false
      end
    end

    describe "#views_only" do
      it "sets extraction to views only" do
        config.views_only
        
        expect(config.include_models).to be false
        expect(config.include_views).to be true
        expect(config.include_controllers).to be false
      end
    end

    describe "#controllers_only" do
      it "sets extraction to controllers only" do
        config.controllers_only
        
        expect(config.include_models).to be false
        expect(config.include_views).to be false
        expect(config.include_controllers).to be true
      end
    end

    describe "#mv_mode" do
      it "sets extraction to models and views" do
        config.mv_mode
        
        expect(config.include_models).to be true
        expect(config.include_views).to be true
        expect(config.include_controllers).to be false
      end
    end

    describe "#mc_mode" do
      it "sets extraction to models and controllers" do
        config.mc_mode
        
        expect(config.include_models).to be true
        expect(config.include_views).to be false
        expect(config.include_controllers).to be true
      end
    end

    describe "#vc_mode" do
      it "sets extraction to views and controllers" do
        config.vc_mode
        
        expect(config.include_models).to be false
        expect(config.include_views).to be true
        expect(config.include_controllers).to be true
      end
    end

    describe "#mvc_mode" do
      it "sets extraction to all components" do
        config.mvc_mode
        
        expect(config.include_models).to be true
        expect(config.include_views).to be true
        expect(config.include_controllers).to be true
      end
    end
  end

  describe "#rails_application?" do
    context "when Rails is defined and has root" do
      before do
        stub_const("Rails", double("Rails", root: "/app"))
      end

      it "returns true" do
        expect(config.rails_application?).to be true
      end
    end

    context "when Rails is not defined" do
      before do
        hide_const("Rails") if defined?(Rails)
      end

      it "returns false" do
        expect(config.rails_application?).to be false
      end
    end
  end

  describe "#full_extract_path" do
    context "when in Rails application" do
      before do
        stub_const("Rails", double("Rails", root: Pathname.new("/app")))
      end

      it "returns path relative to Rails root" do
        config.extract_base_path = "custom_extracts"
        expect(config.full_extract_path).to eq("/app/custom_extracts")
      end
    end

    context "when not in Rails application" do
      before do
        hide_const("Rails") if defined?(Rails)
        allow(Dir).to receive(:pwd).and_return("/current")
      end

      it "returns path relative to current directory" do
        config.extract_base_path = "custom_extracts"
        expect(config.full_extract_path).to eq("/current/custom_extracts")
      end
    end
  end

  describe "#apply_mode" do
    it "applies 'm' mode correctly" do
      config.apply_mode('m')
      
      expect(config.include_models).to be true
      expect(config.include_views).to be false
      expect(config.include_controllers).to be false
    end

    it "applies 'v' mode correctly" do
      config.apply_mode('v')
      
      expect(config.include_models).to be false
      expect(config.include_views).to be true
      expect(config.include_controllers).to be false
    end

    it "applies 'c' mode correctly" do
      config.apply_mode('c')
      
      expect(config.include_models).to be false
      expect(config.include_views).to be false
      expect(config.include_controllers).to be true
    end

    it "applies 'mv' mode correctly" do
      config.apply_mode('mv')
      
      expect(config.include_models).to be true
      expect(config.include_views).to be true
      expect(config.include_controllers).to be false
    end

    it "applies 'mc' mode correctly" do
      config.apply_mode('mc')
      
      expect(config.include_models).to be true
      expect(config.include_views).to be false
      expect(config.include_controllers).to be true
    end

    it "applies 'vc' mode correctly" do
      config.apply_mode('vc')
      
      expect(config.include_models).to be false
      expect(config.include_views).to be true
      expect(config.include_controllers).to be true
    end

    it "applies 'mvc' mode correctly" do
      config.apply_mode('mvc')
      
      expect(config.include_models).to be true
      expect(config.include_views).to be true
      expect(config.include_controllers).to be true
    end

    it "handles unknown modes gracefully" do
      expect { config.apply_mode('unknown') }.not_to raise_error
    end
  end

  describe "#current_mode" do
    it "returns 'm' for models only" do
      config.models_only
      expect(config.current_mode).to eq('m')
    end

    it "returns 'v' for views only" do
      config.views_only
      expect(config.current_mode).to eq('v')
    end

    it "returns 'c' for controllers only" do
      config.controllers_only
      expect(config.current_mode).to eq('c')
    end

    it "returns 'mv' for models and views" do
      config.mv_mode
      expect(config.current_mode).to eq('mv')
    end

    it "returns 'mc' for models and controllers" do
      config.mc_mode
      expect(config.current_mode).to eq('mc')
    end

    it "returns 'vc' for views and controllers" do
      config.vc_mode
      expect(config.current_mode).to eq('vc')
    end

    it "returns 'mvc' for all components" do
      config.mvc_mode
      expect(config.current_mode).to eq('mvc')
    end

    it "returns 'custom' for custom combinations" do
      config.include_models = true
      config.include_views = false
      config.include_controllers = false
      config.include_helpers = true
      
      expect(config.current_mode).to eq('custom')
    end
  end
end

