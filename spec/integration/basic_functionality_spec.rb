# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RailsRouteExtractor Integration", type: :integration do
  let(:config) { RailsRouteExtractor::Configuration.new }

  before do
    # Setup a minimal test environment
    RailsRouteExtractor.configure do |config|
      config.verbose = false
      config.extract_base_path = "tmp/test_extracts"
    end
  end

  after do
    # Cleanup test extracts
    FileUtils.rm_rf("tmp/test_extracts") if Dir.exist?("tmp/test_extracts")
  end

  describe "configuration" do
    it "allows configuration changes" do
      RailsRouteExtractor.configure do |config|
        config.verbose = true
        config.include_gems = false
      end

      expect(RailsRouteExtractor.config.verbose).to be true
      expect(RailsRouteExtractor.config.include_gems).to be false
    end

    it "persists configuration across calls" do
      RailsRouteExtractor.configure do |config|
        config.include_models = true
        config.include_views = false
        config.include_controllers = false
      end

      expect(RailsRouteExtractor.config.include_models).to be true
      expect(RailsRouteExtractor.config.include_views).to be false
      expect(RailsRouteExtractor.config.include_controllers).to be false
    end
  end

  describe "GemAnalyzer" do
    let(:gem_analyzer) { RailsRouteExtractor::GemAnalyzer.new(config) }

    it "can be instantiated" do
      expect(gem_analyzer).to be_a(RailsRouteExtractor::GemAnalyzer)
    end

    it "has access to configuration" do
      expect(gem_analyzer.config).to eq(config)
    end

    it "responds to analyze_gems method" do
      expect(gem_analyzer).to respond_to(:analyze_gems)
    end

    it "responds to find_gem_source method" do
      expect(gem_analyzer).to respond_to(:find_gem_source)
    end

    it "responds to extract_gem_files method" do
      expect(gem_analyzer).to respond_to(:extract_gem_files)
    end

    it "responds to get_gem_metadata method" do
      expect(gem_analyzer).to respond_to(:get_gem_metadata)
    end

    it "responds to analyze_gem_dependencies method" do
      expect(gem_analyzer).to respond_to(:analyze_gem_dependencies)
    end
  end

  describe "error classes" do
    it "defines proper error hierarchy" do
      expect(RailsRouteExtractor::Error).to be < StandardError
      expect(RailsRouteExtractor::ConfigurationError).to be < RailsRouteExtractor::Error
      expect(RailsRouteExtractor::ExtractionError).to be < RailsRouteExtractor::Error
      expect(RailsRouteExtractor::AnalysisError).to be < RailsRouteExtractor::Error
    end

    it "allows raising custom errors" do
      expect { raise RailsRouteExtractor::Error, "Test error" }.to raise_error(RailsRouteExtractor::Error)
      expect { raise RailsRouteExtractor::ConfigurationError, "Config error" }.to raise_error(RailsRouteExtractor::ConfigurationError)
      expect { raise RailsRouteExtractor::ExtractionError, "Extraction error" }.to raise_error(RailsRouteExtractor::ExtractionError)
      expect { raise RailsRouteExtractor::AnalysisError, "Analysis error" }.to raise_error(RailsRouteExtractor::AnalysisError)
    end
  end
end

