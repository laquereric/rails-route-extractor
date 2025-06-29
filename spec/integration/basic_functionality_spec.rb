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

  describe "RouteAnalyzer" do
    let(:analyzer) { RailsRouteExtractor::RouteAnalyzer.new(config) }

    it "can be instantiated" do
      expect(analyzer).to be_a(RailsRouteExtractor::RouteAnalyzer)
    end

    it "has access to configuration" do
      expect(analyzer.config).to eq(config)
    end

    it "responds to list_routes method" do
      expect(analyzer).to respond_to(:list_routes)
    end

    it "responds to route_info method" do
      expect(analyzer).to respond_to(:route_info)
    end

    it "responds to analyze_route method" do
      expect(analyzer).to respond_to(:analyze_route)
    end

    it "responds to find_route_files method" do
      expect(analyzer).to respond_to(:find_route_files)
    end

    it "responds to validate_route_pattern method" do
      expect(analyzer).to respond_to(:validate_route_pattern)
    end

    it "responds to parse_route_pattern method" do
      expect(analyzer).to respond_to(:parse_route_pattern)
    end

    it "responds to get_route_metadata method" do
      expect(analyzer).to respond_to(:get_route_metadata)
    end

    it "responds to extract_route_dependencies method" do
      expect(analyzer).to respond_to(:extract_route_dependencies)
    end

    it "responds to generate_route_report method" do
      expect(analyzer).to respond_to(:generate_route_report)
    end
  end

  describe "FileAnalyzer" do
    let(:file_analyzer) { RailsRouteExtractor::FileAnalyzer.new(config) }

    it "can be instantiated" do
      expect(file_analyzer).to be_a(RailsRouteExtractor::FileAnalyzer)
    end

    it "has access to configuration" do
      expect(file_analyzer.config).to eq(config)
    end

    it "responds to analyze_files method" do
      expect(file_analyzer).to respond_to(:analyze_files)
    end

    it "responds to find_model_files method" do
      expect(file_analyzer).to respond_to(:find_model_files)
    end

    it "responds to find_view_files method" do
      expect(file_analyzer).to respond_to(:find_view_files)
    end

    it "responds to find_controller_files method" do
      expect(file_analyzer).to respond_to(:find_controller_files)
    end

    it "responds to analyze_file_content method" do
      expect(file_analyzer).to respond_to(:analyze_file_content)
    end

    it "responds to extract_dependencies method" do
      expect(file_analyzer).to respond_to(:extract_dependencies)
    end

    it "responds to find_partial_files method" do
      expect(file_analyzer).to respond_to(:find_partial_files)
    end

    it "responds to find_helper_files method" do
      expect(file_analyzer).to respond_to(:find_helper_files)
    end

    it "responds to find_concern_files method" do
      expect(file_analyzer).to respond_to(:find_concern_files)
    end

    it "responds to analyze_associations method" do
      expect(file_analyzer).to respond_to(:analyze_associations)
    end

    it "responds to generate_file_summary method" do
      expect(file_analyzer).to respond_to(:generate_file_summary)
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

  describe "ExtractManager" do
    let(:manager) { RailsRouteExtractor::ExtractManager.new(config) }

    it "can be instantiated" do
      expect(manager).to be_a(RailsRouteExtractor::ExtractManager)
    end

    it "has access to configuration" do
      expect(manager.config).to eq(config)
    end

    it "responds to extract_route method" do
      expect(manager).to respond_to(:extract_route)
    end

    it "responds to extract_routes method" do
      expect(manager).to respond_to(:extract_routes)
    end

    it "responds to cleanup_extracts method" do
      expect(manager).to respond_to(:cleanup_extracts)
    end

    it "responds to extract_stats method" do
      expect(manager).to respond_to(:extract_stats)
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

  describe "module interface" do
    it "provides expected module methods" do
      expect(RailsRouteExtractor).to respond_to(:extract_route)
      expect(RailsRouteExtractor).to respond_to(:extract_routes)
      expect(RailsRouteExtractor).to respond_to(:list_routes)
      expect(RailsRouteExtractor).to respond_to(:route_info)
      expect(RailsRouteExtractor).to respond_to(:cleanup_extracts)
    end

    it "provides configuration methods" do
      expect(RailsRouteExtractor).to respond_to(:configure)
      expect(RailsRouteExtractor).to respond_to(:config)
    end
  end
end

