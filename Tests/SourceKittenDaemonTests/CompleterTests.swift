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
        
        if let s = result.asJSONString() {
            XCTAssertTrue(s =~ "sourcetext.*init\\(x:")
        }
    }
    
    func testCompletingEnumConstructor() {
        let result = completer.complete(
            URL(fileURLWithPath: completeEnumConstructorFixturePath()),
            offset: 143)
        
        if let s = result.asJSONString() {
            XCTAssertTrue(s =~ "sourcetext.*project\\(")
            XCTAssertTrue(s =~ "sourcetext.*workspace\\(")
            XCTAssertTrue(s =~ "sourcetext.*folder\\(")
        }
    }
    
    func testCompletingAMethod() {
        let result = completer.complete(
            URL(fileURLWithPath: completeMethodFixturePath()),
            offset: 149)
        
        if let s = result.asJSONString() {
            XCTAssertTrue(s =~ "sourcetext.*sdkRoot")
            XCTAssertTrue(s =~ "sourcetext.*target")
            XCTAssertTrue(s =~ "sourcetext.*moduleName")
            XCTAssertTrue(s =~ "sourcetext.*sourceObjects")
            XCTAssertTrue(s =~ "sourcetext.*frameworkSearchPaths")
        }
    }
    
    func testCompletingAMethodFromFramework() {
        let result = completer.complete(
            URL(fileURLWithPath: completeMethodFromFrameworkFixturePath()),
            offset: 69)
        
        if let s = result.asJSONString() {
            XCTAssertTrue(s =~ "sourcetext.*devices.withMediaType:")
        }
    }
    
    func testCompletingAnImportStatement() {
        let result = completer.complete(
            URL(fileURLWithPath: completeImportFixturePath()),
            offset: 7)
        
        if let s = result.asJSONString() {
            XCTAssertTrue(s =~ "sourcetext.*AVFoundation")
        }
    }
    
}
