# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RouteExtract do
  it "has a version number" do
    expect(RouteExtract::VERSION).not_to be nil
  end

  describe ".configure" do
    it "yields a configuration object" do
      expect { |b| RouteExtract.configure(&b) }.to yield_with_args(RouteExtract::Configuration)
    end

    it "allows setting configuration options" do
      RouteExtract.configure do |config|
        config.verbose = true
        config.include_gems = false
      end

      expect(RouteExtract.config.verbose).to be true
      expect(RouteExtract.config.include_gems).to be false
    end
  end

  describe ".config" do
    it "returns the current configuration" do
      expect(RouteExtract.config).to be_a(RouteExtract::Configuration)
    end
  end

  describe ".extract_route" do
    let(:route_pattern) { "test#index" }
    let(:options) { { mode: "mvc" } }

    before do
      # Mock the ExtractManager
      allow_any_instance_of(RouteExtract::ExtractManager).to receive(:extract_route)
        .with(route_pattern, options)
        .and_return({
          success: true,
          extract_path: "/tmp/test_extract",
          files_count: 5,
          total_size: "10 KB"
        })
    end

    it "delegates to ExtractManager" do
      result = RouteExtract.extract_route(route_pattern, options)
      
      expect(result[:success]).to be true
      expect(result[:extract_path]).to eq("/tmp/test_extract")
      expect(result[:files_count]).to eq(5)
    end
  end

  describe ".extract_routes" do
    let(:route_patterns) { ["test#index", "test#show"] }
    let(:options) { { mode: "mvc" } }

    before do
      allow_any_instance_of(RouteExtract::ExtractManager).to receive(:extract_routes)
        .with(route_patterns, options)
        .and_return({
          success: true,
          successful_count: 2,
          failed_count: 0,
          total_files: 10,
          total_size: "20 KB"
        })
    end

    it "delegates to ExtractManager" do
      result = RouteExtract.extract_routes(route_patterns, options)
      
      expect(result[:success]).to be true
      expect(result[:successful_count]).to eq(2)
      expect(result[:failed_count]).to eq(0)
    end
  end

  describe ".list_routes" do
    before do
      allow_any_instance_of(RouteExtract::RouteAnalyzer).to receive(:list_routes)
        .and_return([
          {
            pattern: "test#index",
            controller: "test",
            action: "index",
            method: "GET",
            name: "test_index",
            helper: "test_index_path"
          }
        ])
    end

    it "delegates to RouteAnalyzer" do
      routes = RouteExtract.list_routes
      
      expect(routes).to be_an(Array)
      expect(routes.first[:controller]).to eq("test")
      expect(routes.first[:action]).to eq("index")
    end
  end

  describe ".route_info" do
    let(:route_pattern) { "test#index" }

    before do
      allow_any_instance_of(RouteExtract::RouteAnalyzer).to receive(:route_info)
        .with(route_pattern)
        .and_return({
          pattern: "test#index",
          controller: "test",
          action: "index",
          method: "GET",
          files: { models: [], views: [], controllers: [] }
        })
    end

    it "delegates to RouteAnalyzer" do
      info = RouteExtract.route_info(route_pattern)
      
      expect(info[:controller]).to eq("test")
      expect(info[:action]).to eq("index")
      expect(info[:files]).to be_a(Hash)
    end
  end

  describe ".cleanup_extracts" do
    let(:options) { { force: true } }

    before do
      allow_any_instance_of(RouteExtract::ExtractManager).to receive(:cleanup_extracts)
        .with(options)
        .and_return({
          success: true,
          removed_count: 3,
          space_freed: "15 MB"
        })
    end

    it "delegates to ExtractManager" do
      result = RouteExtract.cleanup_extracts(options)
      
      expect(result[:success]).to be true
      expect(result[:removed_count]).to eq(3)
      expect(result[:space_freed]).to eq("15 MB")
    end
  end
end

