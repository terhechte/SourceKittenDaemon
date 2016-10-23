import PackageDescription

let package = Package(
  name: "SourceKittenDaemon",

  targets: [
    Target(name: "SourceKittenDaemon"),
    Target(name: "sourcekittend", dependencies: [.Target(name: "SourceKittenDaemon")])
  ],

  dependencies: [
    .Package(url: "https://github.com/Carthage/Commandant.git", Version(0, 11, 2)),
    .Package(url: "https://github.com/nanzhong/SourceKitten.git", Version(0, 14, 2)),
    .Package(url: "https://github.com/vapor/vapor.git", Version(1, 1, 1)),
    .Package(url: "https://github.com/nanzhong/Xcode.swift.git", Version(0, 4, 0))
  ],

  exclude: [
    "old"
  ]
)
