# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRouteExtractor do
  it "has a version number" do
    expect(RailsRouteExtractor::VERSION).not_to be nil
  end

  describe ".configure" do
    it "yields configuration object" do
      expect { |b| RailsRouteExtractor.configure(&b) }.to yield_with_args(RailsRouteExtractor::Configuration)
    end

    it "allows configuration changes" do
      RailsRouteExtractor.configure do |config|
        config.verbose = true
        config.include_gems = false
      end

      expect(RailsRouteExtractor.config.verbose).to be true
      expect(RailsRouteExtractor.config.include_gems).to be false
    end
  end

  describe ".config" do
    it "returns configuration object" do
      expect(RailsRouteExtractor.config).to be_a(RailsRouteExtractor::Configuration)
    end

    it "creates new configuration if none exists" do
      RailsRouteExtractor.configuration = nil
      expect(RailsRouteExtractor.config).to be_a(RailsRouteExtractor::Configuration)
    end
  end

  describe ".extract_route" do
    let(:route_pattern) { "users#index" }
    let(:options) { { mode: "mvc" } }

    it "delegates to ExtractManager" do
      allow_any_instance_of(RailsRouteExtractor::ExtractManager).to receive(:extract_route)
        .with(route_pattern, options)
        .and_return({ success: true })

      result = RailsRouteExtractor.extract_route(route_pattern, options)

      expect(result).to eq({ success: true })
    end
  end

  describe ".extract_routes" do
    let(:route_patterns) { ["users#index", "posts#show"] }
    let(:options) { { mode: "mvc" } }

    it "delegates to ExtractManager" do
      allow_any_instance_of(RailsRouteExtractor::ExtractManager).to receive(:extract_routes)
        .with(route_patterns, options)
        .and_return({ success: true })

      result = RailsRouteExtractor.extract_routes(route_patterns, options)

      expect(result).to eq({ success: true })
    end
  end

  describe ".list_routes" do
    it "delegates to RouteAnalyzer" do
      allow_any_instance_of(RailsRouteExtractor::RouteAnalyzer).to receive(:list_routes)
        .and_return([
          { controller: "users", action: "index", path: "/users" },
          { controller: "posts", action: "show", path: "/posts/:id" }
        ])

      routes = RailsRouteExtractor.list_routes

      expect(routes).to be_an(Array)
      expect(routes.length).to eq(2)
    end
  end

  describe ".route_info" do
    let(:route_pattern) { "users#index" }

    it "delegates to RouteAnalyzer" do
      allow_any_instance_of(RailsRouteExtractor::RouteAnalyzer).to receive(:route_info)
        .with(route_pattern)
        .and_return({ controller: "users", action: "index", path: "/users" })

      info = RailsRouteExtractor.route_info(route_pattern)

      expect(info).to eq({ controller: "users", action: "index", path: "/users" })
    end
  end

  describe ".cleanup_extracts" do
    let(:options) { { older_than: "7d" } }

    it "delegates to ExtractManager" do
      allow_any_instance_of(RailsRouteExtractor::ExtractManager).to receive(:cleanup_extracts)
        .with(options)
        .and_return({ cleaned: 5 })

      result = RailsRouteExtractor.cleanup_extracts(options)

      expect(result).to eq({ cleaned: 5 })
    end
  end
end

