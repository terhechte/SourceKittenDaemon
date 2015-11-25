
import XCTest
import SourceKittenFramework
@testable import SourceKittenDaemon

class ProjectTests : XCTestCase {

    var project: Project!

    override func setUp() {
        super.setUp()
        project = Project.Project(project: xcodeprojFixturePath())
    }

    func testProjectFileURLIsCorrect() {
        XCTAssertEqual(project.projectFileURL()!.path, xcodeprojFixturePath())
    }

    func testProjectDirIsCorrect() {
        XCTAssertEqual(project.projectDir(), projectDirFixturePath())
    }

}
    
