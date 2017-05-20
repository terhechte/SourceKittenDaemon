import PackageDescription

var package = Package(
  name: "SourceKittenDaemon",

  targets: [
    Target(name: "SourceKittenDaemon"),
    Target(name: "sourcekittend", dependencies: [.Target(name: "SourceKittenDaemon")])
  ],

  dependencies: [
    .Package(url: "https://github.com/Carthage/Commandant.git", versions: Version(0, 12, 0)..<Version(0, 12, .max)),
    .Package(url: "https://github.com/jpsim/SourceKitten.git", versions: Version(0, 17, 0)..<Version(0, 17, .max)),
    .Package(url: "https://github.com/envoy/Embassy.git",
                 majorVersion: 3),
    .Package(url: "https://github.com/felix91gr/XcodeEdit.git", majorVersion: 1),
  ],

  exclude: [
    "Tests/SourceKittenDaemonTests/Fixtures/Sources"
  ]
)

#if os(Linux)
package.dependencies.append(.Package(url: "https://github.com/felix91gr/FileSystemWatcher.git",
        majorVersion: 1))
#endif
