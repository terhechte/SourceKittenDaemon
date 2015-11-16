//
//  SourceKittenDaemonTests.swift
//  SourceKittenDaemonTests
//
//  Created by Benedikt Terhechte on 15/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import XCTest
import SourceKittenFramework
@testable import SourceKittenDaemon



// Tests still need fixtures.
class SourceKittenDaemonTests: XCTestCase {
    
    var server: CompletionServer? = nil
    let port = 9982
    
    override func setUp() {
        super.setUp()
        let project = ProjectType.Folder(path: "")
        let completer = Completer(project: project)
        
        // FIXME: What happens if the port is blocked? Continue until we find a working port?
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
            self.server = SourceKittenDaemon.CompletionServer(completer: completer, port: self.port)
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func serverURLWithCommand(command: String, timeout: NSTimeInterval = 5.0) -> NSURLRequest {
        let request = NSURLRequest(URL: NSURL(string: "http://localhost:\(self.port)/\(command)")!)
        let mutableRequest = (request.mutableCopy() as? NSMutableURLRequest)!
        mutableRequest.timeoutInterval = timeout
        return mutableRequest
    }
    
    func testResponse() {
        let request = self.serverURLWithCommand("complete")
        let result = try? NSURLConnection.sendSynchronousRequest(request, returningResponse: nil)
        XCTAssertNotNil(result, "Has to get a proper result")
        let jsonResponse = try? NSJSONSerialization.JSONObjectWithData(result!, options: [])
        XCTAssertNotNil(jsonResponse, "Expected proper json response")
        XCTAssertTrue((jsonResponse?.isKindOfClass(NSDictionary.classForCoder())) != nil, "Expected dictionary")
        let errorMessage = (jsonResponse! as? NSDictionary)!["error"]
        XCTAssertNotNil(errorMessage, "Expected an error message")
    }
    
    func testStopServer() {
        self.server?.stop()
        self.server = nil
        let request = self.serverURLWithCommand("stop", timeout: 1.0)
        let expectation = expectationWithDescription("Expect the server to be offline")
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            sleep(1)
            
            let result = try? NSURLConnection.sendSynchronousRequest(request, returningResponse: nil)
            print("result", result)
            if result == nil {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    expectation.fulfill()
                })
            }
        }
        
        waitForExpectationsWithTimeout(4, handler: nil)
    }
}
class SourceKittenDaemonCompletionTests: XCTestCase {
    
    var contents: String!
    var folder: String!
    var completer: Completer!
    var fileInProject = "CompletionTarget.swift"
    
    override func setUp() {
        super.setUp()
        
        let environment = NSProcessInfo.processInfo().environment
        guard let projectDir = environment["project-dir"]
            else { fatalError("Needs current project dir via project-dir environment variable for test") }
        
        self.folder = "\(projectDir)/SourceKittenDaemonTests/Fixtures/FitureCompletionTests/FitureCompletionTests.xcodeproj"
        
        let originalFile = "\(projectDir)/SourceKittenDaemonTests/Fixtures/FitureCompletionTests/FitureCompletionTests/\(self.fileInProject)"
        guard let contents = try? String(contentsOfFile: originalFile)
            else { fatalError("Could not read \(originalFile) for unit tests") }
        self.contents = contents
        
        let project = ProjectType.Project(project: folder)
        guard let parser = XcodeParser(project: project, targetName: nil)
            else { fatalError("Could not create parser for \(folder)") }
                
        self.completer = Completer(project: project, parser: parser)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func temporaryFileForTestingWith(code: String) throws -> (path: String, offset: Int) {
        let newContent = self.contents + code
        let offset = (newContent.characters.count - 1)
        let uid = NSProcessInfo.processInfo().globallyUniqueString
        let path = NSTemporaryDirectory()
        try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        let filePath = path.stringByAppendingString("\(uid).swift")
        try newContent.writeToFile(filePath, atomically: true, encoding: NSUTF8StringEncoding)
        return (path: filePath, offset: offset)
    }
    
    func testCompanyOne() {
        do {
            let (path, offset) = try self.temporaryFileForTestingWith("company1.")
            let result = self.completer.complete(path, fileInProject: self.fileInProject, offset: offset)
            
            guard case .Success(let items) = result
                else { XCTAssertTrue(false, "Needs items in the success case") ; fatalError() }
            
            XCTAssertTrue(items.count == 4, "Needs 4 results")
            
        } catch let error {
            XCTAssertTrue(false, "Could not create a temporary file: \(error)")
        }
    }
}
