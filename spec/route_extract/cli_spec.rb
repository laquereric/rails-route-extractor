# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RouteExtract::CLI do
  let(:cli) { described_class.new }

  describe "#extract" do
    let(:route_pattern) { "users#index" }
    
    before do
      allow(RouteExtract).to receive(:extract_route).and_return({
        success: true,
        extract_path: "/tmp/test_extract",
        files_count: 5,
        total_size: "10 KB"
      })
    end

    it "calls RouteExtract.extract_route with correct parameters" do
      expect(RouteExtract).to receive(:extract_route).with(route_pattern, {
        mode: "mvc",
        include_gems: true,
        include_tests: false,
        compress: false
      })
      
      cli.extract(route_pattern)
    end

    it "handles successful extraction" do
      expect { cli.extract(route_pattern) }.to output(/Successfully extracted/).to_stdout
    end

    it "handles failed extraction" do
      allow(RouteExtract).to receive(:extract_route).and_return({
        success: false,
        error: "Route not found"
      })
      
      expect { cli.extract(route_pattern) }.to output(/Failed to extract/).to_stdout
    end

    it "accepts mode option" do
      expect(RouteExtract).to receive(:extract_route).with(route_pattern, hash_including(mode: "mv"))
      
      cli.options = { "mode" => "mv" }
      cli.extract(route_pattern)
    end

    it "accepts include-gems option" do
      expect(RouteExtract).to receive(:extract_route).with(route_pattern, hash_including(include_gems: false))
      
      cli.options = { "include-gems" => false }
      cli.extract(route_pattern)
    end

    it "accepts include-tests option" do
      expect(RouteExtract).to receive(:extract_route).with(route_pattern, hash_including(include_tests: true))
      
      cli.options = { "include-tests" => true }
      cli.extract(route_pattern)
    end

    it "accepts compress option" do
      expect(RouteExtract).to receive(:extract_route).with(route_pattern, hash_including(compress: true))
      
      cli.options = { "compress" => true }
      cli.extract(route_pattern)
    end
  end

  describe "#extract_multiple" do
    let(:route_patterns) { "users#index,posts#show" }
    
    before do
      allow(RouteExtract).to receive(:extract_routes).and_return({
        success: true,
        successful_count: 2,
        failed_count: 0,
        total_files: 10,
        total_size: "20 KB"
      })
    end

    it "splits route patterns and calls RouteExtract.extract_routes" do
      expect(RouteExtract).to receive(:extract_routes).with(["users#index", "posts#show"], anything)
      
      cli.extract_multiple(route_patterns)
    end

    it "handles successful batch extraction" do
      expect { cli.extract_multiple(route_patterns) }.to output(/Successfully extracted 2 routes/).to_stdout
    end

    it "handles failed batch extraction" do
      allow(RouteExtract).to receive(:extract_routes).and_return({
        success: false,
        successful_count: 1,
        failed_count: 1,
        error: "Some routes failed"
      })
      
      expect { cli.extract_multiple(route_patterns) }.to output(/Batch extraction completed with errors/).to_stdout
    end
  end

  describe "#list" do
    before do
      allow(RouteExtract).to receive(:list_routes).and_return([
        {
          pattern: "users#index",
          controller: "users",
          action: "index",
          method: "GET",
          name: "users",
          helper: "users_path"
        },
        {
          pattern: "posts#show",
          controller: "posts",
          action: "show",
          method: "GET",
          name: "post",
          helper: "post_path"
        }
      ])
    end

    it "displays routes in table format" do
      expect { cli.list }.to output(/users#index.*GET/).to_stdout
      expect { cli.list }.to output(/posts#show.*GET/).to_stdout
    end

    it "filters routes when filter option is provided" do
      cli.options = { "filter" => "users" }
      
      expect { cli.list }.to output(/users#index/).to_stdout
      expect { cli.list }.not_to output(/posts#show/).to_stdout
    end

    it "outputs JSON format when requested" do
      cli.options = { "format" => "json" }
      
      expect { cli.list }.to output(/\[/).to_stdout
      expect { cli.list }.to output(/"pattern"/).to_stdout
    end

    it "outputs CSV format when requested" do
      cli.options = { "format" => "csv" }
      
      expect { cli.list }.to output(/Pattern,Controller,Action/).to_stdout
      expect { cli.list }.to output(/users#index,users,index/).to_stdout
    end
  end

  describe "#info" do
    let(:route_pattern) { "users#index" }
    
    before do
      allow(RouteExtract).to receive(:route_info).and_return({
        pattern: "users#index",
        controller: "users",
        action: "index",
        method: "GET",
        name: "users",
        helper: "users_path",
        path: "/users",
        files: {
          models: ["app/models/user.rb"],
          views: ["app/views/users/index.html.erb"],
          controllers: ["app/controllers/users_controller.rb"]
        }
      })
    end

    it "displays route information" do
      expect { cli.info(route_pattern) }.to output(/Route Information/).to_stdout
      expect { cli.info(route_pattern) }.to output(/Controller: users/).to_stdout
      expect { cli.info(route_pattern) }.to output(/Action: index/).to_stdout
    end

    it "displays associated files" do
      expect { cli.info(route_pattern) }.to output(/Models:/).to_stdout
      expect { cli.info(route_pattern) }.to output(/app\/models\/user\.rb/).to_stdout
    end

    it "handles non-existent routes" do
      allow(RouteExtract).to receive(:route_info).and_return(nil)
      
      expect { cli.info("nonexistent#route") }.to output(/Route not found/).to_stdout
    end
  end

  describe "#cleanup" do
    before do
      allow(RouteExtract).to receive(:cleanup_extracts).and_return({
        success: true,
        removed_count: 3,
        space_freed: "15 MB"
      })
    end

    it "calls RouteExtract.cleanup_extracts" do
      expect(RouteExtract).to receive(:cleanup_extracts).with({})
      
      cli.cleanup
    end

    it "handles successful cleanup" do
      expect { cli.cleanup }.to output(/Successfully cleaned up 3 extracts/).to_stdout
    end

    it "handles failed cleanup" do
      allow(RouteExtract).to receive(:cleanup_extracts).and_return({
        success: false,
        error: "Permission denied"
      })
      
      expect { cli.cleanup }.to output(/Cleanup failed/).to_stdout
    end

    it "accepts older-than option" do
      cli.options = { "older-than" => "7d" }
      
      expect(RouteExtract).to receive(:cleanup_extracts).with(hash_including(older_than: "7d"))
      
      cli.cleanup
    end

    it "accepts force option" do
      cli.options = { "force" => true }
      
      expect(RouteExtract).to receive(:cleanup_extracts).with(hash_including(force: true))
      
      cli.cleanup
    end
  end

  describe "#stats" do
    before do
      manager = double("manager")
      allow(RouteExtract::ExtractManager).to receive(:new).and_return(manager)
      allow(manager).to receive(:extraction_statistics).and_return({
        extracts_count: 5,
        total_size: "50 MB",
        oldest: DateTime.new(2023, 1, 1),
        newest: DateTime.new(2023, 12, 1)
      })
    end

    it "displays extraction statistics" do
      expect { cli.stats }.to output(/Extraction Statistics/).to_stdout
      expect { cli.stats }.to output(/Total extracts: 5/).to_stdout
      expect { cli.stats }.to output(/Total size: 50 MB/).to_stdout
    end
  end

  describe "error handling" do
    it "handles RouteExtract::Error exceptions" do
      allow(RouteExtract).to receive(:extract_route).and_raise(RouteExtract::Error, "Test error")
      
      expect { cli.extract("test#route") }.to output(/Error: Test error/).to_stdout
    end

    it "handles general exceptions" do
      allow(RouteExtract).to receive(:extract_route).and_raise(StandardError, "Unexpected error")
      
      expect { cli.extract("test#route") }.to output(/Unexpected error: Unexpected error/).to_stdout
    end
  end

  describe "verbose output" do
    before do
      cli.options = { "verbose" => true }
      
      allow(RouteExtract).to receive(:configure).and_yield(RouteExtract.config)
      allow(RouteExtract).to receive(:extract_route).and_return({
        success: true,
        extract_path: "/tmp/test",
        files_count: 5,
        total_size: "10 KB"
      })
    end

    it "enables verbose configuration" do
      expect(RouteExtract.config).to receive(:verbose=).with(true)
      
      cli.extract("test#route")
    end
  end
end

