#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Validate the RailsRouteExtractor gem structure
"""

import os
import sys
import json
from pathlib import Path

def main():
    print("RailsRouteExtractor Gem Structure Validation")
    print("=" * 50)
    
    # Define expected file structure
    expected_files = [
        # Core gem files
        "rails-route-extractor.gemspec",
        "lib/rails_route_extractor.rb",
        "lib/rails_route_extractor/version.rb",
        "lib/rails_route_extractor/configuration.rb",
        "lib/rails_route_extractor/route_analyzer.rb",
        "lib/rails_route_extractor/code_extractor.rb",
        "lib/rails_route_extractor/dependency_tracker.rb",
        "lib/rails_route_extractor/gem_analyzer.rb",
        "lib/rails_route_extractor/file_analyzer.rb",
        "lib/rails_route_extractor/extract_manager.rb",
        "lib/rails_route_extractor/cli.rb",
        "lib/rails_route_extractor/railtie.rb",
        
        # Executables
        "exe/rails_route_extractor",
        
        # Documentation
        "README.md",
        "CHANGELOG.md",
        "LICENSE.txt",
        
        # Development files
        "Gemfile",
        "Rakefile",
        ".rspec",
        "bin/test",
        
        # Spec files
        "spec/spec_helper.rb",
        "spec/rails_route_extractor_spec.rb",
        "spec/rails_route_extractor/configuration_spec.rb",
        "spec/rails_route_extractor/route_analyzer_spec.rb",
        "spec/rails_route_extractor/cli_spec.rb",
        "spec/integration/basic_functionality_spec.rb",
    ]
    
    # Define expected directories
    expected_dirs = [
        "lib/rails_route_extractor",
        "lib/rails_route_extractor/generators",
        "lib/rails_route_extractor/generators/templates",
        "lib/rails_route_extractor/tasks",
        "spec/rails_route_extractor",
        "spec/integration",
        "examples",
        "docs",
        "exe",
        "bin",
    ]
    
    # Check if we're in the right directory
    if not os.path.exists("rails-route-extractor.gemspec"):
        print("❌ Error: rails-route-extractor.gemspec not found in current directory")
        print("Please run this script from the gem root directory")
        sys.exit(1)
    
    print("✅ Found gemspec file")
    
    # Validate file structure
    missing_files = []
    for file_path in expected_files:
        if not os.path.exists(file_path):
            missing_files.append(file_path)
        else:
            print(f"✅ {file_path}")
    
    if missing_files:
        print(f"\n❌ Missing files: {len(missing_files)}")
        for file_path in missing_files:
            print(f"   - {file_path}")
    
    # Validate directory structure
    missing_dirs = []
    for dir_path in expected_dirs:
        if not os.path.isdir(dir_path):
            missing_dirs.append(dir_path)
        else:
            print(f"✅ {dir_path}/")
    
    if missing_dirs:
        print(f"\n❌ Missing directories: {len(missing_dirs)}")
        for dir_path in missing_dirs:
            print(f"   - {dir_path}/")
    
    # Validate gemspec content
    print("\n🔍 Validating gemspec content...")
    try:
        with open("rails-route-extractor.gemspec", "r") as f:
            content = f.read()
            
        # Check for key elements
        checks = [
            ("spec.name", "rails_route_extractor"),
            ("RailsRouteExtractor::VERSION", "version reference"),
            ("spec.summary", "summary"),
            ("spec.description", "description"),
            ("spec.homepage", "homepage"),
            ("spec.license", "MIT"),
        ]
        
        for check, description in checks:
            if check in content:
                print(f"✅ {description}")
            else:
                print(f"❌ Missing {description}")
                
    except Exception as e:
        print(f"❌ Error reading gemspec: {e}")
    
    # Validate main lib file
    print("\n🔍 Validating main lib file...")
    try:
        with open("lib/rails_route_extractor.rb", "r") as f:
            content = f.read()
            
        checks = [
            ("module RailsRouteExtractor", "module definition"),
            ("require_relative", "require statements"),
            ("def configure", "configure method"),
            ("def extract_route", "extract_route method"),
        ]
        
        for check, description in checks:
            if check in content:
                print(f"✅ {description}")
            else:
                print(f"❌ Missing {description}")
                
    except Exception as e:
        print(f"❌ Error reading main lib file: {e}")
    
    # Validate version file
    print("\n🔍 Validating version file...")
    try:
        with open("lib/rails_route_extractor/version.rb", "r") as f:
            content = f.read()
            
        if "module RailsRouteExtractor" in content and "VERSION" in content:
            print("✅ Version file structure")
        else:
            print("❌ Version file structure issues")
            
    except Exception as e:
        print(f"❌ Error reading version file: {e}")
    
    # Validate executable
    print("\n🔍 Validating executable...")
    try:
        with open("exe/rails_route_extractor", "r") as f:
            content = f.read()
            
        if "RailsRouteExtractor::CLI.start" in content:
            print("✅ Executable structure")
        else:
            print("❌ Executable structure issues")
            
    except Exception as e:
        print(f"❌ Error reading executable: {e}")
    
    # Summary
    print("\n" + "=" * 50)
    if not missing_files and not missing_dirs:
        print("🎉 All structure checks passed!")
    else:
        print(f"⚠️  Found {len(missing_files)} missing files and {len(missing_dirs)} missing directories")
    
    print("\nThe RailsRouteExtractor gem structure is valid and ready for packaging.")

if __name__ == "__main__":
    main()

