// swift-tools-version:4.2

import PackageDescription

var package = Package(
  name: "SourceKittenDaemon",

  dependencies: [
    .package(url: "https://github.com/Carthage/Commandant.git", .branch("master")),
    .package(url: "https://github.com/jpsim/SourceKitten.git", .branch("master")),
    .package(url: "https://github.com/envoy/Embassy.git", .branch("master")),
    .package(url: "https://github.com/tomlokhorst/XcodeEdit", .branch("develop")),
    .package(url: "https://github.com/antitypical/Result.git", .branch("master"))
    
  ],

  targets: [
    .target(
	name: "SourceKittenDaemon",
	dependencies: ["Commandant", "SourceKittenFramework", "XcodeEdit", "Embassy", "Result" ]
    ),
    .target(
	name: "sourcekittend", 
	dependencies: ["SourceKittenDaemon"])
  ]
)

#if os(Linux)
package.dependencies.append(.Package(url: "https://github.com/felix91gr/FileSystemWatcher.git",
        majorVersion: 1))
#endif
