# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Basic Functionality Integration", type: :integration do
  let(:config) { RouteExtract::Configuration.new }

  before do
    # Setup a minimal test environment
    RouteExtract.configure do |config|
      config.verbose = false
      config.extract_base_path = "tmp/test_extracts"
    end
  end

  after do
    # Cleanup test extracts
    FileUtils.rm_rf("tmp/test_extracts") if Dir.exist?("tmp/test_extracts")
  end

  describe "Configuration" do
    it "can be configured and accessed" do
      RouteExtract.configure do |config|
        config.verbose = true
        config.include_gems = false
      end

      expect(RouteExtract.config.verbose).to be true
      expect(RouteExtract.config.include_gems).to be false
    end

    it "supports mode shortcuts" do
      RouteExtract.configure do |config|
        config.models_only
      end

      expect(RouteExtract.config.include_models).to be true
      expect(RouteExtract.config.include_views).to be false
      expect(RouteExtract.config.include_controllers).to be false
    end
  end

  describe "Route Analysis" do
    let(:analyzer) { RouteExtract::RouteAnalyzer.new(config) }

    context "when Rails is not available" do
      before do
        hide_const("Rails") if defined?(Rails)
      end

      it "handles missing Rails gracefully" do
        expect { analyzer.list_routes }.not_to raise_error
      end
    end

    context "when Rails is available" do
      before do
        # Mock minimal Rails environment
        routes_double = double("routes")
        allow(routes_double).to receive(:routes).and_return([])
        
        stub_const("Rails", double("Rails", 
          application: double(routes: routes_double),
          root: Pathname.new("/tmp")
        ))
      end

      it "can list routes without errors" do
        routes = analyzer.list_routes
        expect(routes).to be_an(Array)
      end

      it "can check route existence" do
        allow(analyzer).to receive(:list_routes).and_return([
          { pattern: "test#index", controller: "test", action: "index" }
        ])

        expect(analyzer.route_exists?("test#index")).to be true
        expect(analyzer.route_exists?("nonexistent#action")).to be false
      end
    end
  end

  describe "File Analysis" do
    let(:file_analyzer) { RouteExtract::FileAnalyzer.new(config) }
    let(:test_file) { "tmp/test_file.rb" }

    before do
      FileUtils.mkdir_p("tmp")
      File.write(test_file, <<~RUBY)
        class TestController < ApplicationController
          def index
            @users = User.all
            render :index
          end
          
          def show
            @user = User.find(params[:id])
            if @user.present?
              render :show
            else
              redirect_to users_path
            end
          end
        end
      RUBY
    end

    after do
      FileUtils.rm_f(test_file)
    end

    it "can analyze a Ruby file" do
      analysis = file_analyzer.analyze_file(test_file)
      
      expect(analysis[:type]).to eq(:ruby)
      expect(analysis[:lines][:total]).to be > 0
      expect(analysis[:complexity][:method_count]).to eq(2)
      expect(analysis[:complexity][:class_count]).to eq(1)
    end

    it "can analyze multiple files" do
      results = file_analyzer.analyze_files([test_file])
      
      expect(results[:files]).to be_an(Array)
      expect(results[:files].length).to eq(1)
      expect(results[:summary][:total_files]).to eq(1)
      expect(results[:summary][:file_types][:rb]).to eq(1)
    end
  end

  describe "Gem Analysis" do
    let(:gem_analyzer) { RouteExtract::GemAnalyzer.new(config) }

    it "can analyze a specific gem" do
      # Test with a gem that should be available (json is part of Ruby standard library)
      gem_info = gem_analyzer.analyze_gem("json")
      
      # The gem might not be found in test environment, so we just check structure
      expect(gem_info).to be_a(Hash)
      expect(gem_info).to have_key(:name)
      expect(gem_info).to have_key(:found)
    end

    it "handles non-existent gems gracefully" do
      gem_info = gem_analyzer.analyze_gem("nonexistent_gem_12345")
      
      expect(gem_info[:found]).to be false
      expect(gem_info[:error]).to be_present
    end
  end

  describe "Extract Manager" do
    let(:manager) { RouteExtract::ExtractManager.new(config) }

    it "can get extraction statistics" do
      stats = manager.extraction_statistics
      
      expect(stats).to be_a(Hash)
      expect(stats).to have_key(:extracts_count)
      expect(stats).to have_key(:total_size)
    end

    it "can list extracts" do
      extracts = manager.list_extracts
      
      expect(extracts).to be_an(Array)
    end

    it "can cleanup extracts" do
      result = manager.cleanup_extracts(force: true)
      
      expect(result).to be_a(Hash)
      expect(result).to have_key(:success)
      expect(result).to have_key(:removed_count)
    end
  end

  describe "Error Handling" do
    it "defines custom error classes" do
      expect(RouteExtract::Error).to be < StandardError
      expect(RouteExtract::ConfigurationError).to be < RouteExtract::Error
      expect(RouteExtract::ExtractionError).to be < RouteExtract::Error
      expect(RouteExtract::AnalysisError).to be < RouteExtract::Error
    end

    it "handles configuration errors gracefully" do
      expect {
        RouteExtract.configure do |config|
          config.extract_base_path = nil
        end
      }.not_to raise_error
    end
  end

  describe "Module Interface" do
    it "provides main extraction methods" do
      expect(RouteExtract).to respond_to(:extract_route)
      expect(RouteExtract).to respond_to(:extract_routes)
      expect(RouteExtract).to respond_to(:list_routes)
      expect(RouteExtract).to respond_to(:route_info)
      expect(RouteExtract).to respond_to(:cleanup_extracts)
    end

    it "provides configuration methods" do
      expect(RouteExtract).to respond_to(:configure)
      expect(RouteExtract).to respond_to(:config)
    end
  end
end

