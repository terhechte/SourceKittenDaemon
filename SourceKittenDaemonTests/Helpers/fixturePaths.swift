import Foundation

let environment = NSProcessInfo.processInfo().environment

public func projectDirFixturePath() -> String {
    return environment["project-dir"]!
}

public func xcodeprojFixturePath() -> String {
    return environment["project-file-path"]!
}
