# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRouteExtractor::RouteAnalyzer do
  let(:config) { RailsRouteExtractor::Configuration.new }
  let(:analyzer) { described_class.new(config) }

  # Set up a consistent mock Rails environment for all tests in this file
  before do
    # Mock Rails application and routes
    routes_double = double("routes")
    allow(routes_double).to receive(:routes).and_return([
      double("route1",
        app: double('app1', is_a?: false),
        verb: "GET",
        path: double(spec: "/users"),
        defaults: { controller: "users", action: "index" },
        name: "users",
        constraints:{}, 
        requirements:{}
      ),
      double("route2",
        app: double('app2', is_a?: false),
        verb: "POST",
        path: double(spec: "/users"),
        defaults: { controller: "users", action: "create" },
        name: "users",
        constraints:{},
        requirements:{}
      )
    ])
    
    app_double = double("application", routes: routes_double)
    stub_const("Rails", double("Rails", application: app_double, root: Pathname.new("/fake/rails/root")))
  end

  describe "#initialize" do
    it "stores the configuration" do
      expect(analyzer.config).to eq(config)
    end
  end

  describe "#list_routes" do
    it "returns an array of route hashes" do
      routes = analyzer.list_routes
      expect(routes).to be_an(Array)
      expect(routes.length).to eq(2)
      
      first_route = routes[1]
      expect(first_route[:controller]).to eq("users")
      expect(first_route[:action]).to eq("index")
      expect(first_route[:method]).to eq("GET")
      expect(first_route[:pattern]).to eq("users#index")
    end
  end

  describe "#route_exists?" do
    before do
      allow(analyzer).to receive(:list_routes).and_return([
        { pattern: "users#index", controller: "users", action: "index" },
        { pattern: "posts#show", controller: "posts", action: "show" }
      ])
    end

    it "returns true for existing routes" do
      expect(analyzer.route_exists?("users#index")).to be true
      expect(analyzer.route_exists?("posts#show")).to be true
    end

    it "returns false for non-existing routes" do
      expect(analyzer.route_exists?("nonexistent#action")).to be false
    end
  end

  describe "#route_info" do
    let(:route_data) do
      {
        pattern: "users#index",
        controller: "users",
        action: "index",
        method: "GET",
        name: "users",
        helper: "users_path",
        path: "/users"
      }
    end

    before do
      allow(analyzer).to receive(:list_routes).and_return([route_data])
      allow(analyzer).to receive(:find_associated_files).and_return({
        models: ["app/models/user.rb"],
        views: ["app/views/users/index.html.erb"],
        controllers: ["app/controllers/users_controller.rb"],
        helpers: ["app/helpers/users_helper.rb"],
        concerns: []
      })
    end

    it "returns nil for non-existing routes" do
      info = analyzer.route_info("nonexistent#action")
      expect(info).to be_nil
    end
  end

  describe "#find_routes_by_pattern" do
    before do
      allow(analyzer).to receive(:list_routes).and_return([
        { pattern: "users#index", controller: "users", action: "index" },
        { pattern: "users#show", controller: "users", action: "show" },
        { pattern: "posts#index", controller: "posts", action: "index" },
        { pattern: "admin/users#index", controller: "admin/users", action: "index" }
      ])
    end

    it "finds routes matching a simple pattern" do
      routes = analyzer.find_routes_by_pattern("users")
      
      expect(routes.length).to eq(3)
      expect(routes.map { |r| r[:pattern] }).to include("users#index", "users#show", "admin/users#index")
    end

    it "finds routes matching a specific controller pattern" do
      routes = analyzer.find_routes_by_pattern("admin/users")
      
      expect(routes.length).to eq(1)
      expect(routes.first[:pattern]).to eq("admin/users#index")
    end

    it "returns empty array for non-matching patterns" do
      routes = analyzer.find_routes_by_pattern("nonexistent")
      expect(routes).to be_empty
    end
  end

  describe "#route_dependencies" do
    before do
      allow(analyzer).to receive(:find_associated_files).and_return({
        models: ["app/models/user.rb", "app/models/profile.rb"],
        views: ["app/views/users/index.html.erb"],
        controllers: ["app/controllers/users_controller.rb"],
        helpers: ["app/helpers/users_helper.rb"],
        concerns: ["app/controllers/concerns/authentication.rb"]
      })
      

    end

  end

  
  describe "private methods" do
    describe "#find_associated_files" do
      let(:controller) { "users" }
      let(:action) { "index" }

      before do
        # Mock file system
        allow(Dir).to receive(:glob).and_return([])
        allow(File).to receive(:exist?).and_return(false)
        
        # Mock specific files
        allow(File).to receive(:exist?).with("app/controllers/users_controller.rb").and_return(true)
        allow(File).to receive(:exist?).with("app/models/user.rb").and_return(true)
        allow(Dir).to receive(:glob).with("app/views/users/**/*").and_return([
          "app/views/users/index.html.erb",
          "app/views/users/_user.html.erb"
        ])
      end

      it "finds associated files for a route" do
        files = analyzer.send(:find_associated_files, controller, action)
        
        expect(files[:controllers]).to include("app/controllers/users_controller.rb")
        expect(files[:models]).to include("app/models/user.rb")
        expect(files[:views]).to include("app/views/users/index.html.erb")
      end
    end

    describe "#extract_route_pattern" do
      it "extracts pattern from route defaults" do
        defaults = { controller: "users", action: "index" }
        pattern = analyzer.send(:extract_route_pattern, defaults)
        
        expect(pattern).to eq("users#index")
      end

      it "handles namespaced controllers" do
        defaults = { controller: "admin/users", action: "show" }
        pattern = analyzer.send(:extract_route_pattern, defaults)
        
        expect(pattern).to eq("admin/users#show")
      end
    end

    describe "#extract_route_helper" do
      it "extracts helper name from route name" do
        helper = analyzer.send(:extract_route_helper, "users", "GET")
        expect(helper).to eq("users_path")
      end

      it "handles different HTTP methods" do
        helper = analyzer.send(:extract_route_helper, "user", "POST")
        expect(helper).to eq("user_path")
      end

      it "handles nil route names" do
        helper = analyzer.send(:extract_route_helper, nil, "GET")
        expect(helper).to be_nil
      end
    end
  end
end

