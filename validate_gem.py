#!/usr/bin/env python3.11

import os
import sys
import json

def validate_gem_structure():
    """Validate the RouteExtract gem structure"""
    print("RouteExtract Gem Structure Validation")
    print("=" * 40)
    
    # Required files and directories
    required_items = [
        ('file', 'lib/route_extract.rb'),
        ('file', 'lib/route_extract/version.rb'),
        ('file', 'lib/route_extract/configuration.rb'),
        ('file', 'lib/route_extract/route_analyzer.rb'),
        ('file', 'lib/route_extract/code_extractor.rb'),
        ('file', 'lib/route_extract/dependency_tracker.rb'),
        ('file', 'lib/route_extract/gem_analyzer.rb'),
        ('file', 'lib/route_extract/file_analyzer.rb'),
        ('file', 'lib/route_extract/extract_manager.rb'),
        ('file', 'lib/route_extract/cli.rb'),
        ('file', 'lib/route_extract/railtie.rb'),
        ('dir', 'lib/route_extract/generators'),
        ('dir', 'lib/route_extract/tasks'),
        ('file', 'exe/route_extract'),
        ('file', 'route_extract.gemspec'),
        ('file', 'README.md'),
        ('file', 'LICENSE.txt'),
        ('file', 'CHANGELOG.md'),
        ('file', 'Gemfile'),
        ('file', 'Rakefile'),
        ('dir', 'spec'),
        ('dir', 'docs'),
        ('dir', 'examples')
    ]
    
    missing_items = []
    
    for item_type, path in required_items:
        if item_type == 'file' and not os.path.isfile(path):
            missing_items.append(f"File: {path}")
        elif item_type == 'dir' and not os.path.isdir(path):
            missing_items.append(f"Directory: {path}")
    
    if missing_items:
        print("✗ FAIL: Missing required items:")
        for item in missing_items:
            print(f"  - {item}")
        return False
    else:
        print("✓ PASS: All required files and directories present")
    
    # Check file contents
    print("\nValidating file contents...")
    
    # Check version file
    try:
        with open('lib/route_extract/version.rb', 'r') as f:
            version_content = f.read()
            if 'VERSION = "0.1.0"' in version_content:
                print("✓ PASS: Version file contains correct version")
            else:
                print("✗ FAIL: Version file missing or incorrect")
                return False
    except Exception as e:
        print(f"✗ FAIL: Error reading version file: {e}")
        return False
    
    # Check gemspec file
    try:
        with open('route_extract.gemspec', 'r') as f:
            gemspec_content = f.read()
            if 'spec.name' in gemspec_content and 'route_extract' in gemspec_content:
                print("✓ PASS: Gemspec file appears valid")
            else:
                print("✗ FAIL: Gemspec file missing or incorrect")
                return False
    except Exception as e:
        print(f"✗ FAIL: Error reading gemspec file: {e}")
        return False
    
    # Check executable
    if os.access('exe/route_extract', os.X_OK):
        print("✓ PASS: CLI executable has correct permissions")
    else:
        print("✗ FAIL: CLI executable missing execute permissions")
        return False
    
    # Check documentation
    doc_files = ['docs/user_guide.md', 'docs/api_reference.md']
    for doc_file in doc_files:
        if os.path.isfile(doc_file) and os.path.getsize(doc_file) > 1000:
            print(f"✓ PASS: {doc_file} exists and has content")
        else:
            print(f"✗ FAIL: {doc_file} missing or too small")
            return False
    
    # Check examples
    example_files = ['examples/basic_usage.rb', 'examples/advanced_usage.rb']
    for example_file in example_files:
        if os.path.isfile(example_file) and os.path.getsize(example_file) > 500:
            print(f"✓ PASS: {example_file} exists and has content")
        else:
            print(f"✗ FAIL: {example_file} missing or too small")
            return False
    
    # Check test files
    test_files = [
        'spec/route_extract_spec.rb',
        'spec/route_extract/configuration_spec.rb',
        'spec/route_extract/route_analyzer_spec.rb',
        'spec/route_extract/cli_spec.rb',
        'spec/integration/basic_functionality_spec.rb'
    ]
    for test_file in test_files:
        if os.path.isfile(test_file) and os.path.getsize(test_file) > 500:
            print(f"✓ PASS: {test_file} exists and has content")
        else:
            print(f"✗ FAIL: {test_file} missing or too small")
            return False
    
    return True

def count_lines_of_code():
    """Count lines of code in the gem"""
    print("\nCode Statistics:")
    print("-" * 20)
    
    total_lines = 0
    total_files = 0
    
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.rb'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r') as f:
                        lines = len(f.readlines())
                        total_lines += lines
                        total_files += 1
                        print(f"  {file_path}: {lines} lines")
                except Exception as e:
                    print(f"  Error reading {file_path}: {e}")
    
    print(f"\nTotal: {total_files} Ruby files, {total_lines} lines of code")
    
    # Count test files
    test_lines = 0
    test_files = 0
    
    for root, dirs, files in os.walk('spec'):
        for file in files:
            if file.endswith('.rb'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r') as f:
                        lines = len(f.readlines())
                        test_lines += lines
                        test_files += 1
                except Exception as e:
                    pass
    
    print(f"Tests: {test_files} test files, {test_lines} lines of test code")
    
    # Count documentation
    doc_lines = 0
    doc_files = 0
    
    for root, dirs, files in os.walk('docs'):
        for file in files:
            if file.endswith('.md'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r') as f:
                        lines = len(f.readlines())
                        doc_lines += lines
                        doc_files += 1
                except Exception as e:
                    pass
    
    print(f"Documentation: {doc_files} markdown files, {doc_lines} lines")

def main():
    if not validate_gem_structure():
        print("\n" + "=" * 40)
        print("Validation FAILED! ✗")
        sys.exit(1)
    
    count_lines_of_code()
    
    print("\n" + "=" * 40)
    print("Validation PASSED! ✓")
    print("\nThe RouteExtract gem structure is valid and ready for packaging.")
    print("\nNext steps:")
    print("1. Build the gem: gem build route_extract.gemspec")
    print("2. Install locally: gem install route_extract-*.gem")
    print("3. Test in a Rails application")

if __name__ == "__main__":
    main()

