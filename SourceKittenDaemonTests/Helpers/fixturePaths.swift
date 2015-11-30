import Foundation

let environment = NSProcessInfo.processInfo().environment

public func projectDirFixturePath() -> String {
    return environment["FIXTURE_PROJECT_DIR"]!
}

public func xcodeprojFixturePath() -> String {
    return environment["FIXTURE_PROJECT_FILE_PATH"]!
}

public func completeEnumConstructorFixturePath() -> String {
    return environment["FIXTURE_PROJECT_DIR"]! +
            "/SourceKittenDaemonTests/Fixtures/CompleteEnumConstructorFixture.swift"
}

public func completeMethodFixturePath() -> String {
    return environment["FIXTURE_PROJECT_DIR"]! +
            "/SourceKittenDaemonTests/Fixtures/CompleteMethodFixture.swift"
}
