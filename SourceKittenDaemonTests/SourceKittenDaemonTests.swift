//
//  SourceKittenDaemonTests.swift
//  SourceKittenDaemonTests
//
//  Created by Benedikt Terhechte on 15/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import XCTest
@testable import SourceKittenDaemon

extension Completer {
    func complete(filePath: String, fileInProject: String, offset: Int) -> CompletionResult {
        return CompletionResult.Failure(message: "Done")
    }
}

class SourceKittenDaemonServerTests: XCTestCase {
    
    var server: CompletionServer? = nil
    let port = 9981
    
    override func setUp() {
        super.setUp()
        let project = ProjectType.Folder(path: "")
        let completer = Completer(project: project)
        
        // FIXME: What happens if the port is blocked? Continue until we find a working port?
        self.server = SourceKittenDaemon.CompletionServer(completer: completer, port: self.port)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        self.server?.stop()
    }
    
    func testResponse() {
        let request = NSURLRequest(URL: NSURL(string: "http://localhost:\(self.port)/complete")!)
        let result = try? NSURLConnection.sendSynchronousRequest(request, returningResponse: nil)
        XCTAssertNotNil(result, "Has to get a proper result")
        let responseString = String(data: result!, encoding: NSUTF8StringEncoding)
        XCTAssertTrue(responseString == "{\"error\": \"Done\"}")
    }
}
