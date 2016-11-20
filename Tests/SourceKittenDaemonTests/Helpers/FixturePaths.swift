import Foundation

let environment = ProcessInfo.processInfo.environment

public func projectDirFixturePath() -> String {
    return environment["FIXTURE_PROJECT_DIR"]!
}

public func xcodeprojFixturePath() -> String {
    return environment["FIXTURE_PROJECT_FILE_PATH"]!
}

public func completeConstructorFixturePath() -> String {
    return environment["FIXTURE_PATH"]! +
            "/Sources/CompleteConstructorFixture.swift"
}

public func completeEnumConstructorFixturePath() -> String {
    return environment["FIXTURE_PATH"]! +
            "/Sources/CompleteEnumConstructorFixture.swift"
}

public func completeMethodFixturePath() -> String {
    return environment["FIXTURE_PATH"]! +
            "/Sources/CompleteMethodFixture.swift"
}

public func completeMethodFromFrameworkFixturePath() -> String {
    return environment["FIXTURE_PATH"]! +
            "/Sources/CompleteMethodFromFrameworkFixture.swift"
}

public func completeImportFixturePath() -> String {
    return environment["FIXTURE_PATH"]! +
            "/Sources/CompleteImportFixture.swift"
}
