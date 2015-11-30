import XCTest
import SourceKittenFramework
@testable import SourceKittenDaemon

class CompleterTests : XCTestCase {

    var type: ProjectType!
    var project: Project!
    var completer: Completer!

    override func setUp() {
        super.setUp()
        type = ProjectType.Project(project: xcodeprojFixturePath())
        project = try! Project(type: type, configuration: "Debug")
        completer = Completer(project: project)
    }

    func testCompletingAConstructor() {
        let result = completer.complete(
                         NSURL(fileURLWithPath: completeConstructorFixturePath()),
                         offset: 26)

        if let d = result.asJSON(),
           s = NSString(bytes: d.bytes,
                        length: d.length,
                        encoding: NSUTF8StringEncoding) as String? {
            XCTAssertTrue(s =~ "sourcetext.*init\\(x:")
        }
    }

    func testCompletingEnumConstructor() {
        let result = completer.complete(
                         NSURL(fileURLWithPath: completeEnumConstructorFixturePath()),
                         offset: 143)

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
        let result = completer.complete(
                         NSURL(fileURLWithPath: completeMethodFixturePath()),
                         offset: 149)

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

    func testCompletingAMethodFromFramework() {
        let result = completer.complete(
                         NSURL(fileURLWithPath: completeMethodFromFrameworkFixturePath()),
                         offset: 82)

        if let d = result.asJSON(),
           s = NSString(bytes: d.bytes,
                        length: d.length,
                        encoding: NSUTF8StringEncoding) as String? {
            XCTAssertTrue(s =~ "sourcetext.*parseResponse")
        }
    }

    // @TODO : Currently fails, sourcekit doesn't seem to be including third party frameworks?
    func testCompletingAnImportStatement() {
        let result = completer.complete(
                         NSURL(fileURLWithPath: completeEnumConstructorFixturePath()),
                         offset: 7)

        if let d = result.asJSON(),
           s = NSString(bytes: d.bytes,
                        length: d.length,
                        encoding: NSUTF8StringEncoding) as String? {
            XCTAssertTrue(s =~ "sourcetext.*AVFoundation")
            XCTAssertTrue(s =~ "sourcetext.*SourceKittenFramework")
            XCTAssertTrue(s =~ "sourcetext.*Taylor")
            XCTAssertTrue(s =~ "sourcetext.*Commandant")
        }
    }

}
