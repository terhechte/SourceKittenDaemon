
import XCTest
import SourceKittenFramework
@testable import SourceKittenDaemon

class ProjectTypeTests : XCTestCase {

    var project: ProjectType!

    override func setUp() {
        super.setUp()
        project = ProjectType.Project(project: xcodeprojFixturePath())
    }

    func testProjectFileURLIsCorrect() {
        XCTAssertEqual(project.projectFileURL()!.path, xcodeprojFixturePath())
    }

    func testProjectDirIsCorrect() {
        XCTAssertEqual(project.projectDir(), projectDirFixturePath())
    }

}
    
