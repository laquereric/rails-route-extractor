# frozen_string_literal: true

require "spec_helper"

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
      expect(RailsRouteExtractor).to receive(:extract_route).with(route_pattern, {
        mode: "mvc",
        include_gems: true,
        include_tests: false,
        compress: false,
        verbose: false
      })

      cli.extract(route_pattern)
    end

    it "passes mode option" do
      expect(RailsRouteExtractor).to receive(:extract_route).with(route_pattern, hash_including(mode: "mv"))
      cli.extract(route_pattern, "--mode", "mv")
    end

    it "passes include_gems option" do
      expect(RailsRouteExtractor).to receive(:extract_route).with(route_pattern, hash_including(include_gems: false))
      cli.extract(route_pattern, "--no-gems")
    end

    it "passes include_tests option" do
      expect(RailsRouteExtractor).to receive(:extract_route).with(route_pattern, hash_including(include_tests: true))
      cli.extract(route_pattern, "--include-tests")
    end

    it "passes compress option" do
      expect(RailsRouteExtractor).to receive(:extract_route).with(route_pattern, hash_including(compress: true))
      cli.extract(route_pattern, "--compress")
    end

    it "passes verbose option" do
      expect(RailsRouteExtractor).to receive(:extract_route).with(route_pattern, hash_including(verbose: true))
      cli.extract(route_pattern, "--verbose")
    end
  end

  describe "#extract_multiple" do
    let(:route_patterns) { "users#index,posts#show" }

    before do
      allow(RailsRouteExtractor).to receive(:extract_routes).and_return({
        success: true,
        successful_count: 2,
        failed_count: 0
      })
    end

    it "splits route patterns and calls RailsRouteExtractor.extract_routes" do
      expect(RailsRouteExtractor).to receive(:extract_routes).with(["users#index", "posts#show"], anything)
      cli.extract_multiple(route_patterns)
    end

    it "passes options correctly" do
      expect(RailsRouteExtractor).to receive(:extract_routes).with(["users#index", "posts#show"], {
        mode: "mvc",
        include_gems: true,
        include_tests: false,
        compress: false,
        verbose: false
      })
      cli.extract_multiple(route_patterns)
    end
  end

  describe "#list" do
    before do
      allow(RailsRouteExtractor).to receive(:list_routes).and_return([
        { controller: "users", action: "index", path: "/users" },
        { controller: "posts", action: "show", path: "/posts/:id" }
      ])
    end

    it "calls RailsRouteExtractor.list_routes" do
      expect(RailsRouteExtractor).to receive(:list_routes)
      cli.list
    end

    it "displays routes in table format" do
      expect { cli.list }.to output(/Controller.*Action.*Path/).to_stdout
    end
  end

  describe "#info" do
    let(:route_pattern) { "users#index" }

    before do
      allow(RailsRouteExtractor).to receive(:route_info).and_return({
        controller: "users",
        action: "index",
        path: "/users",
        method: "GET"
      })
    end

    it "calls RailsRouteExtractor.route_info" do
      expect(RailsRouteExtractor).to receive(:route_info).with(route_pattern)
      cli.info(route_pattern)
    end

    it "displays route information" do
      expect { cli.info(route_pattern) }.to output(/Controller.*users/).to_stdout
    end

    it "handles nil route info" do
      allow(RailsRouteExtractor).to receive(:route_info).and_return(nil)
      expect { cli.info(route_pattern) }.to output(/Route not found/).to_stdout
    end
  end

  describe "#cleanup" do
    before do
      allow(RailsRouteExtractor).to receive(:cleanup_extracts).and_return({
        success: true,
        removed_count: 3
      })
    end

    it "calls RailsRouteExtractor.cleanup_extracts" do
      expect(RailsRouteExtractor).to receive(:cleanup_extracts).with({})
      cli.cleanup
    end

    it "passes older_than option" do
      expect(RailsRouteExtractor).to receive(:cleanup_extracts).with(hash_including(older_than: "7d"))
      cli.cleanup("--older-than", "7d")
    end

    it "passes force option" do
      expect(RailsRouteExtractor).to receive(:cleanup_extracts).with(hash_including(force: true))
      cli.cleanup("--force")
    end
  end

  describe "#stats" do
    before do
      allow(RailsRouteExtractor::ExtractManager).to receive(:new).and_return(manager)
      allow(manager).to receive(:extract_stats).and_return({
        total_extracts: 10,
        total_size: "50 MB",
        oldest_extract: "2023-01-01",
        newest_extract: "2023-12-01"
      })
    end

    let(:manager) { double("manager") }

    it "displays extract statistics" do
      expect { cli.stats }.to output(/Total Extracts.*10/).to_stdout
    end
  end

  describe "error handling" do
    it "handles RailsRouteExtractor::Error exceptions" do
      allow(RailsRouteExtractor).to receive(:extract_route).and_raise(RailsRouteExtractor::Error, "Test error")
      expect { cli.extract("test#index") }.to output(/Error.*Test error/).to_stdout
    end

    it "handles unexpected exceptions" do
      allow(RailsRouteExtractor).to receive(:extract_route).and_raise(StandardError, "Unexpected error")
      expect { cli.extract("test#index") }.to output(/Unexpected error/).to_stdout
    end
  end

  describe "configuration" do
    it "allows configuration via CLI" do
      allow(RailsRouteExtractor).to receive(:configure).and_yield(RailsRouteExtractor.config)
      allow(RailsRouteExtractor).to receive(:extract_route).and_return({ success: true })
      allow(RailsRouteExtractor.config).to receive(:verbose=)

      cli.extract("test#index", "--verbose")
      expect(RailsRouteExtractor.config).to receive(:verbose=).with(true)
    end
  end
end

