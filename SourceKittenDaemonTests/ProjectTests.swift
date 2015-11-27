
import XCTest
import SourceKittenFramework
@testable import SourceKittenDaemon

class ProjectTests : XCTestCase {

    var type: ProjectType!
    var project: Project!

    override func setUp() {
        super.setUp()
        type = ProjectType.Project(project: xcodeprojFixturePath())
        project = try! Project(type: type)
    }

    func testProjectDirIsCorrect() {
        XCTAssertEqual(projectDirFixturePath(), project.projectDir.path)
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

    func testItCanOverrideTheSchemesTarget() {
        // Since we only have one target in our fixture,
        // this just tests that it tries to use the new target
        var thrown = false
        do {
            project = try Project(type: type, target: "Random")
            XCTAssertEqual("Random", project.target)
        } catch (_) {
            thrown = true
        }

        XCTAssertTrue(thrown)
    }

    func testItCanOverrideTheSchemesConfiguration() {
        XCTAssertEqual("Release", project.configuration)
        project = try! Project(type: type, configuration: "Debug")
        XCTAssertEqual("Debug", project.configuration)
    }

    func testReturnsTheCorrectModuleName() {
        XCTAssertEqual("SourceKittenDaemon", project.moduleName)
    }

    func testReturnsTheCorrectSDKRoot() {
        XCTAssertTrue(project.sdkRoot =~ "^/Applications/Xcode.app/Contents/Developer/Platforms.*")
    }

    func testReturnsAListOfFrameworkSearchPaths() {
        XCTAssertEqual(["\(self.project.projectDir.path!)/Carthage/Build/Mac"],
                        project.frameworkSearchPaths)
    }

    func testReturnsCustomSwiftCompilerFlags() {
        XCTAssertEqual(["-DFLAG_FIXTURE"], project.customSwiftCompilerFlags)
    }

    func testReturnsGccPreprocessorDefinitions() {
        project = try! Project(type: type, configuration: "Debug")
        XCTAssertEqual(["DEBUG=1"], project.gccPreprocessorDefinitions)
    }

}
