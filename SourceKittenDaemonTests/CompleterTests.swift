import XCTest
import SourceKittenFramework
@testable import SourceKittenDaemon

class CompleterTests : XCTestCase {

    var type: ProjectType!
    var project: Project!
    var completer: Completer!

    let methodFixtureURL = NSURL(fileURLWithPath: completeMethodFixturePath())
    let enumConstructorFixtureURL = NSURL(fileURLWithPath: completeEnumConstructorFixturePath())

    override func setUp() {
        super.setUp()
        type = ProjectType.Project(project: xcodeprojFixturePath())
        project = try! Project(type: type, configuration: "Debug")
        completer = Completer(project: project)
    }

    func testCompletingEnumConstructor() {
        let result = completer.complete(enumConstructorFixtureURL, offset: 143)
        if let d = result.asJSON(),
           s = NSString(bytes: d.bytes,
                        length: d.length,
                        encoding: NSUTF8StringEncoding) as String? {
            XCTAssertTrue(s =~ "sourcetext.*Project\\(")
            XCTAssertTrue(s =~ "sourcetext.*Workspace\\(")
            XCTAssertTrue(s =~ "sourcetext.*Folder\\(")
        }
    }

    func testCompletingAMethod() {
        let result = completer.complete(methodFixtureURL, offset: 149)
        if let d = result.asJSON(),
           s = NSString(bytes: d.bytes,
                        length: d.length,
                        encoding: NSUTF8StringEncoding) as String? {
            XCTAssertTrue(s =~ "sourcetext.*sdkRoot")
            XCTAssertTrue(s =~ "sourcetext.*target")
            XCTAssertTrue(s =~ "sourcetext.*moduleName")
            XCTAssertTrue(s =~ "sourcetext.*sourceObjects")
            XCTAssertTrue(s =~ "sourcetext.*frameworkSearchPaths")
        }
    }

    func testCompletingAConstructor() {
    }

    func testCompletingAnImportStatement() {
    }

    func testCompletionRespectsSwiftFlags() {
    }
    
}
