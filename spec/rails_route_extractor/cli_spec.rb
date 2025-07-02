# frozen_string_literal: true

require "spec_helper"
require "rails_route_extractor/cli"

RSpec.describe RailsRouteExtractor::CLI do
  let(:cli) { described_class.new }

  describe "#extract" do
    let(:route_pattern) { "users#index" }

    before do
      allow(RailsRouteExtractor).to receive(:extract_route).and_return({
        success: true,
        extract_path: "/tmp/test_extract",
        files_count: 5
      })
    end

    it "calls RailsRouteExtractor.extract_route with correct parameters" do
      expect(RailsRouteExtractor).to receive(:extract_route).with(route_pattern, hash_including(mode: "mvc"))
      cli.invoke(:extract, [route_pattern])
    end

    it "passes mode option" do
      expect(RailsRouteExtractor).to receive(:extract_route).with(route_pattern, hash_including(mode: "full"))
      cli.invoke(:extract, [route_pattern], { mode: "full" })
    end

    it "passes include_gems option" do
      expect(RailsRouteExtractor).to receive(:extract_route).with(route_pattern, hash_including(include_gems: false))
      cli.invoke(:extract, [route_pattern], { include_gems: false })
    end

    it "passes include_tests option" do
      expect(RailsRouteExtractor).to receive(:extract_route).with(route_pattern, hash_including(include_tests: true))
      cli.invoke(:extract, [route_pattern], { include_tests: true })
    end

    it "passes compress option" do
      expect(RailsRouteExtractor).to receive(:extract_route).with(route_pattern, hash_including(compress: true))
      cli.invoke(:extract, [route_pattern], { compress: true })
    end

    it "passes verbose option" do
      expect(RailsRouteExtractor).to receive(:configure).with(hash_including(verbose: true))
      cli.invoke(:extract, [route_pattern], { verbose: true })
    end
  end

  describe "#extract_multiple" do
    let(:route_patterns) { ["users#index", "posts#show"] }

    before do
      allow(RailsRouteExtractor).to receive(:extract_routes).and_return({
        success: true,
        successful_count: 2
      })
    end

    it "splits route patterns and calls RailsRouteExtractor.extract_routes" do
      expect(RailsRouteExtractor).to receive(:extract_routes).with(route_patterns, any_args)
      cli.invoke(:extract_multiple, [route_patterns.join(",")])
    end

    it "passes options correctly" do
      expect(RailsRouteExtractor).to receive(:extract_routes).with(route_patterns, hash_including(mode: "full"))
      cli.invoke(:extract_multiple, [route_patterns.join(",")], { mode: "full" })
    end
  end

  describe "#list" do
    before do
      allow(RailsRouteExtractor).to receive(:list_routes).and_return([
        { pattern: "/users", controller: "users", action: "index", method: "GET" },
        { pattern: "/posts/:id", controller: "posts", action: "show", method: "GET" }
      ])
    end

    it "calls RailsRouteExtractor.list_routes" do
      expect(RailsRouteExtractor).to receive(:list_routes)
      cli.list
    end

    it "displays routes in table format" do
      expect { cli.list }.to output(/Pattern.*Controller.*Action.*Method/).to_stdout
    end
  end

  describe "#info" do
    let(:route_pattern) { "users#index" }

    before do
      allow(RailsRouteExtractor).to receive(:route_info).and_return({
        pattern: "/users",
        controller: "users",
        action: "index",
        method: "GET"
      })
    end

    it "calls RailsRouteExtractor.route_info" do
      expect(RailsRouteExtractor).to receive(:route_info).with(route_pattern)
      cli.info(route_pattern)
    end

    it "displays route information" do
      expect { cli.info(route_pattern) }.to output(/Route Information/).to_stdout
    end
  end
end

