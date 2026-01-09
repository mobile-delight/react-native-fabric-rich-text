#!/usr/bin/env ruby
# frozen_string_literal: true

# This script configures the FabricRichTextExample Xcode project to:
# 1. Create a test target (FabricRichTextTests)
# 2. Add test files to the test target
#
# Run from example/ios directory after `pod install`

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH = 'FabricRichTextExample.xcodeproj'
MAIN_TARGET_NAME = 'FabricRichTextExample'
TEST_TARGET_NAME = 'FabricRichTextTests'

# Test files in example/ios/FabricRichTextTests
TEST_DIR = 'FabricRichTextTests'
TEST_FILES = Dir.glob("#{TEST_DIR}/*.{swift,mm,m}").map { |f| File.basename(f) }

def main
  puts "Opening project: #{PROJECT_PATH}"
  project = Xcodeproj::Project.open(PROJECT_PATH)

  main_target = project.targets.find { |t| t.name == MAIN_TARGET_NAME }
  raise "Main target '#{MAIN_TARGET_NAME}' not found" unless main_target

  # Create or find test target
  test_target = project.targets.find { |t| t.name == TEST_TARGET_NAME }

  if test_target.nil?
    puts "\nCreating test target: #{TEST_TARGET_NAME}"
    test_target = project.new_target(:unit_test_bundle, TEST_TARGET_NAME, :ios, '15.1')

    # Configure test target
    test_target.build_configurations.each do |config|
      config.build_settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'io.michaelfay.fabricrichtext.tests'
      config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/FabricRichTextExample.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/FabricRichTextExample'
      config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
      config.build_settings['SWIFT_VERSION'] = '5.0'
      config.build_settings['INFOPLIST_FILE'] = 'FabricRichTextTests/Info.plist'
      config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
      config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
      # Add bridging header for ObjC++ interop
      config.build_settings['SWIFT_OBJC_BRIDGING_HEADER'] = 'FabricRichTextTests-Bridging-Header.h'
    end

    # Add test target dependency on main target
    test_target.add_dependency(main_target)
  else
    puts "\nTest target already exists: #{TEST_TARGET_NAME}"
  end

  # Create Tests group
  tests_group = project.main_group.find_subpath(TEST_TARGET_NAME, true)
  tests_group.set_source_tree('<group>')
  tests_group.set_path(TEST_DIR)

  # Add test files to test target
  puts "\nAdding test files to #{TEST_TARGET_NAME}:"
  TEST_FILES.each do |filename|
    existing = tests_group.files.find { |f| f.path == filename }
    if existing
      puts "  - #{filename} (already exists)"
      # Make sure it's in the build phase
      unless test_target.source_build_phase.files.any? { |f| f.file_ref == existing }
        test_target.source_build_phase.add_file_reference(existing)
        puts "    (added to build phase)"
      end
      next
    end

    file_ref = tests_group.new_reference(filename)
    file_ref.set_source_tree('<group>')
    test_target.source_build_phase.add_file_reference(file_ref)
    puts "  + #{filename}"
  end

  # Create test Info.plist if it doesn't exist
  plist_path = File.join(TEST_DIR, 'Info.plist')
  unless File.exist?(plist_path)
    FileUtils.mkdir_p(TEST_DIR)
    File.write(plist_path, <<~PLIST)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleDevelopmentRegion</key>
        <string>$(DEVELOPMENT_LANGUAGE)</string>
        <key>CFBundleExecutable</key>
        <string>$(EXECUTABLE_NAME)</string>
        <key>CFBundleIdentifier</key>
        <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
        <key>CFBundleInfoDictionaryVersion</key>
        <string>6.0</string>
        <key>CFBundleName</key>
        <string>$(PRODUCT_NAME)</string>
        <key>CFBundlePackageType</key>
        <string>$(PRODUCT_BUNDLE_TYPE)</string>
        <key>CFBundleShortVersionString</key>
        <string>1.0</string>
        <key>CFBundleVersion</key>
        <string>1</string>
      </dict>
      </plist>
    PLIST
    puts "\nCreated: #{plist_path}"
  end

  # Save project
  project.save
  puts "\nProject saved successfully!"
  puts "\nNext steps:"
  puts "  1. Uncomment test target in Podfile"
  puts "  2. Run 'bundle exec pod install'"
  puts "  3. Open FabricRichTextExample.xcworkspace"
  puts "  4. Run tests with Cmd+U"
end

main
