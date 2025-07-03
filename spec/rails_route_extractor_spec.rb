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


end

