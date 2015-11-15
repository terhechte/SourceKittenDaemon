//
//  SourceKittenDaemonTests.swift
//  SourceKittenDaemonTests
//
//  Created by Benedikt Terhechte on 15/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import XCTest
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
    
    func serverURLWithCommand(command: String) -> NSURLRequest {
        let request = NSURLRequest(URL: NSURL(string: "http://localhost:\(self.port)/\(command)")!)
        return request
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
        let request = self.serverURLWithCommand("complete")
        let expectation = expectationWithDescription("Expect the server to be offline")
        
        waitForExpectationsWithTimeout(5) { error in
            let result = try? NSURLConnection.sendSynchronousRequest(request, returningResponse: nil)
            if result == nil {
                expectation.fulfill()
            }
        }
    }
}
