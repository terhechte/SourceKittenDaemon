
import XCTest
import SourceKittenFramework
@testable import SourceKittenDaemon

class ProjectTests : XCTestCase {

    var project: Project!

    override func setUp() {
        super.setUp()
        let type = ProjectType.Project(project: xcodeprojFixturePath())
        project = try! Project(type: type)
    }

    func testProjectDirIsCorrect() {
        XCTAssertEqual(project.projectDir.path, projectDirFixturePath())
    }

    func testReturnsTheCorrectSourceCodeObjects() {
        let sources = project.sourceObjects
                      .map { $0.relativePath.absoluteURL(forProject: self.project) }
                      .filter { $0 != nil }
                      .map { $0!.path! }

        XCTAssert(sources.count > 0)
        XCTAssert(sources.contains { $0 =~ "Project.swift$" })
        XCTAssert(sources.every({ $0 =~ "^\(self.project.projectDir.path!)" }),
                  "Each path starts with \(self.project.projectDir.path!)")
    }

    func testGettingFrameworkObjects() {
        let frameworks = project.frameworkObjects.map { $0.name }
        XCTAssert(frameworks.contains { $0 =~ "SourceKittenFramework.*" })
        XCTAssert(frameworks.contains { $0 =~ "Taylor.*" })
        XCTAssert(frameworks.contains { $0 =~ "Commandant.*" })
    }

    func testCanPassInATarget() {
    }

    func testCanPassInAConfiguration() {
    }

    func testItDefaultsToTheDebugConfiguration() {
    }

    func testReturnsTheCorrectModuleName() {
    }

    func testReturnsTheCorrectSDKPath() {
    }

}
    
