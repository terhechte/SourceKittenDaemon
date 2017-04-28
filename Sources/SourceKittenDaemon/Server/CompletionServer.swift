//
//  CompletionServer.swift
//  SourceKittenDaemon
//
//  Created by Benedikt Terhechte on 12/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation
import Embassy

enum Abort: Error {
    case custom(status: Int, message: String)
}

/**
This runs a simple webserver that can be queried from Emacs to get completions
for a file.
*/
public class CompletionServer {

    let completer: Completer
    let loop: SelectorEventLoop
    
    var server: DefaultHTTPServer?

    public init(project: Project, port: Int) throws {
        let selector = try KqueueSelector()
        self.loop = try SelectorEventLoop(selector: selector)
        self.completer = Completer(project: project)
        self.server = DefaultHTTPServer(eventLoop: loop, port: port, app: requestHandler)
    }

    public func start() throws {
        try server?.start()
        // Run event loop
        loop.runForever()

    }

    private func requestHandler(environ: [String: Any], startResponse: ((String, [(String, String)]) -> Void), sendBody: ((Data) -> Void)) {
        do {
            let returnResult = try routeRequest(environ: environ)
            startResponse("200 OK", [])
            sendBody(Data(returnResult.utf8))
            sendBody(Data())
        } catch Abort.custom(status: let status, message: let message) {
            startResponse("\(status) BAD REQUEST", [])
            sendBody(Data(message.utf8))
            sendBody(Data())
        } catch let error {
            startResponse("500 INTERNAL SERVER ERROR", [])
            sendBody(Data("\(error)".utf8))
            sendBody(Data())
        }
    }
    
    private func routeRequest(environ: [String: Any]) throws -> String {
        let routes = [
            "/ping": servePing,
            "/project": serveProject,
            "/files": serveFiles,
            "/complete": serveComplete,
        ]
        
        guard let path = environ["PATH_INFO"] as? String,
            let route = routes[path] else {
                throw Abort.custom(
                    status: 400,
                    message: "{\"error\": \"Could not generate file list\"}"
                )
        }
        
        return try route(environ)
    }
}

/**
 Concrete implementation of the calls
 */
extension CompletionServer {
    func servePing(environ: [String: Any]) throws -> String {
        return "OK"
    }
    
    func serveProject(environ: [String: Any]) throws -> String {
        return self.completer.project.projectFile.path
    }
    
    func serveFiles(environ: [String: Any]) throws -> String {
        let files = self.completer.sourceFiles()
        guard let jsonFiles = try? JSONSerialization.data(
            withJSONObject: files,
            options: JSONSerialization.WritingOptions.prettyPrinted
            ),
            let filesString = String(data: jsonFiles, encoding: String.Encoding.utf8) else {
                throw Abort.custom(
                    status: 400,
                    message: "{\"error\": \"Could not generate file list\"}"
                )
        }
        return filesString
    }
    
    func serveComplete(environ: [String: Any]) throws -> String {
        guard let offsetString = environ["HTTP_X_OFFSET"] as? String,
            let offset = Int(offsetString) else {
                throw Abort.custom(
                    status: 400,
                    message: "{\"error\": \"Need X-Offset as completion offset for completion\"}"
                )
        }
        
        guard let path = environ["HTTP_X_PATH"] as? String else {
            throw Abort.custom(
                status: 400,
                message: "{\"error\": \"Need X-Path as path to the temporary buffer\"}"
            )
        }
        
        print("[HTTP] GET /complete X-Offset:\(offset) X-Path:\(path)")
        
        let url = URL(fileURLWithPath: path)
        let result = self.completer.complete(url, offset: offset)
        
        switch result {
        case .success(result: _):
            return result.asJSONString()!
        case .failure(message: let msg):
            throw Abort.custom(
                status: 400,
                message: "{\"error\": \"\(msg)\"}"
            )
        }
    }
}
