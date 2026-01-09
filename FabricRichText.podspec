require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "FabricRichText"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => '15.1' }
  s.source       = { :git => "https://github.com/michael-fay/react-native-fabric-rich-text.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift,cpp}", "cpp/**/*.{h,cpp}"
  s.exclude_files = [
    "ios/Tests/**/*",
    "ios/**/RCTModuleProviders.*",
    "ios/**/RCTThirdPartyComponentsProvider.*",
    "ios/**/RCTModulesConformingToProtocolsProvider.*",
    "ios/**/RCTUnstableModulesRequiringMainQueueSetupProvider.*",
    "ios/**/RCTAppDependencyProvider.*",
    "ios/**/ReactAppDependencyProvider.*",
    "ios/generated/android/**/*",
  ]
  s.public_header_files = "ios/FabricRichCoreTextView.h"

  # Localized accessibility strings
  # Use explicit file pattern to ensure Localizable.strings files are included
  s.resource_bundles = {
    'FabricRichTextResources' => ['ios/Resources/**/*.lproj/*']
  }

  s.frameworks = "CoreText", "CoreFoundation"

  s.dependency "SwiftSoup", "~> 2.11"

  install_modules_dependencies(s)
end
