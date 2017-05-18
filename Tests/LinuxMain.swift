import XCTest
@testable import SourceKittenDaemonTests

XCTMain([
    testCase(CompleterTests.allTests),
    testCase(ProjectTests.allTests),
])
