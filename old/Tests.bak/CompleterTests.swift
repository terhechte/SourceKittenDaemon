import XCTest
import SourceKittenFramework
@testable import SourceKittenDaemon

class CompleterTests : XCTestCase {

    var type: ProjectType!
    var project: Project!
    var completer: Completer!

    override func setUp() {
        super.setUp()
        type = ProjectType.project(project: xcodeprojFixturePath())
        project = try! Project(type: type, configuration: "Debug")
        completer = Completer(project: project)
    }

    func testCompletingAConstructor() {
        let result = completer.complete(
                         URL(fileURLWithPath: completeConstructorFixturePath()),
                         offset: 26)

        if let d = result.asJSON(),
           let s = NSString(bytes: d.bytes,
                        length: d.count,
                        encoding: String.Encoding.utf8.rawValue) as String? {
            XCTAssertTrue(s =~ "sourcetext.*init\\(x:")
        }
    }

    func testCompletingEnumConstructor() {
        let result = completer.complete(
                         URL(fileURLWithPath: completeEnumConstructorFixturePath()),
                         offset: 143)

        if let d = result.asJSON(),
           let s = NSString(bytes: d.bytes,
                        length: d.count,
                        encoding: String.Encoding.utf8.rawValue) as String? {
            XCTAssertTrue(s =~ "sourcetext.*Project\\(")
            XCTAssertTrue(s =~ "sourcetext.*Workspace\\(")
            XCTAssertTrue(s =~ "sourcetext.*Folder\\(")
        }
    }

    func testCompletingAMethod() {
        let result = completer.complete(
                         URL(fileURLWithPath: completeMethodFixturePath()),
                         offset: 149)

        if let d = result.asJSON(),
           let s = NSString(bytes: d.bytes,
                        length: d.count,
                        encoding: String.Encoding.utf8.rawValue) as String? {
            XCTAssertTrue(s =~ "sourcetext.*sdkRoot")
            XCTAssertTrue(s =~ "sourcetext.*target")
            XCTAssertTrue(s =~ "sourcetext.*moduleName")
            XCTAssertTrue(s =~ "sourcetext.*sourceObjects")
            XCTAssertTrue(s =~ "sourcetext.*frameworkSearchPaths")
        }
    }

    func testCompletingAMethodFromFramework() {
        let result = NScompleter.complete(
                         URL(fileURLWithPath: completeMethodFromFrameworkFixturePath()),
                         offset: 69)

        if let d = result.asJSON(),
           let s = NSString(bytes: d.bytes,
                        length: d.count,
                        encoding: String.Encoding.utf8.rawValue) as String? {
            XCTAssertTrue(s =~ "sourcetext.*devicesWithMediaType")
        }
    }

    func testCompletingAnImportStatement() {
        let result = completer.complete(
                         URL(fileURLWithPath: completeImportFixturePath()),
                         offset: 7)

        if let d = result.asJSON(),
           let s = NSString(bytes: d.bytes,
                        length: d.count,
                        encoding: String.Encoding.utf8.rawValue) as String? {
            XCTAssertTrue(s =~ "sourcetext.*AVFoundation")
        }
    }

}
