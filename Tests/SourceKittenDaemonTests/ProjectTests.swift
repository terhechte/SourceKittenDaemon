import XCTest
import SourceKittenFramework
@testable import SourceKittenDaemon

class ProjectTests : XCTestCase {

    var type: ProjectType!
    var project: Project!

    override func setUp() {
        super.setUp()
        type = ProjectType.project(project: xcodeprojFixturePath())
        project = try! Project(type: type)
    }

    func testProjectDirIsCorrect() {
        XCTAssertEqual(projectDirFixturePath(), project.projectDir.path)
    }

    func testReturnsTheCorrectSourceCodeObjects() {
        let sources = project.sourceObjects
                      .map { $0.relativePath.absoluteURL(forProject: self.project) }
                      .filter { $0 != nil }
                      .map { $0!.path }

        XCTAssert(sources.count > 0)
        XCTAssert(sources.contains { $0 =~ "Enum.swift$" })
        XCTAssert(sources.every({ $0 =~ "^\(self.project.projectDir.path)" }),
                  "Each path starts with \(self.project.projectDir.path)")
    }

    func testItCanOverrideTheSchemesTarget() {
        var thrown = false
        do {
            project = try Project(type: type, target: "Random")
            XCTAssertEqual("Random", project.target)
        } catch (_) {
            thrown = true
        }

        XCTAssertFalse(thrown)
    }

    func testItCanOverrideTheSchemesConfiguration() {
        XCTAssertEqual("Release", project.configuration)
        project = try! Project(type: type, configuration: "Debug")
        XCTAssertEqual("Debug", project.configuration)
    }

    func testReturnsTheCorrectModuleName() {
        XCTAssertEqual("Fixture", project.moduleName)
    }

    func testReturnsTheCorrectSDKRoot() {
        XCTAssertTrue(project.sdkRoot =~ "^/Applications/Xcode.app/Contents/Developer/Platforms.*")
    }

    func testReturnsAListOfFrameworkSearchPaths() {
        XCTAssert(project.frameworkSearchPaths.count > 0)
    }

    func testReturnsCustomSwiftCompilerFlags() {
        XCTAssert(project.customSwiftCompilerFlags.contains("-DFLAG_FIXTURE"))
    }

    func testReturnsGccPreprocessorDefinitions() {
        project = try! Project(type: type, configuration: "Debug")
        XCTAssertEqual(["DEBUG=1"], project.gccPreprocessorDefinitions)
    }

}

#if os(Linux)

extension ProjectTests {
    static var allTests: [(String, (ProjectTests) -> () throws -> Void)] {
        return [
            ("testProjectDirIsCorrect", testProjectDirIsCorrect),
            ("testReturnsTheCorrectSourceCodeObjects", testReturnsTheCorrectSourceCodeObjects),
            ("testItCanOverrideTheSchemesTarget", testItCanOverrideTheSchemesTarget),
            ("testItCanOverrideTheSchemesConfiguration", testItCanOverrideTheSchemesConfiguration),
            ("testReturnsTheCorrectModuleName", testReturnsTheCorrectModuleName),         
            ("testReturnsTheCorrectSDKRoot", testReturnsTheCorrectSDKRoot),         
            ("testReturnsAListOfFrameworkSearchPaths", testReturnsAListOfFrameworkSearchPaths),         
            ("testReturnsCustomSwiftCompilerFlags", testReturnsCustomSwiftCompilerFlags),         
            ("testReturnsGccPreprocessorDefinitions", testReturnsGccPreprocessorDefinitions),         
                 ]
    }
}

#endif
