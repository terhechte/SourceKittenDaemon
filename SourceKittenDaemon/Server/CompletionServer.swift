//
//  CompletionServer.swift
//  SourceKittenDaemon
//
//  Created by Benedikt Terhechte on 12/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation
import Taylor

/**
This runs a simple webserver that can be queried from Emacs to get completions
for a file. 
*/
public class CompletionServer {
    
    let server: Taylor.Server
    let port: Int
    
    let completer: Completer
    
    internal init(project: Project, port: Int) {
        self.port = port
        self.completer = Completer(project: project)
        self.server = Taylor.Server()
        
        self.server.get("/ping") { (req, res) -> Callback in
            res.bodyString = "OK"
            return .Send
        }

        self.server.get("/project") { (req, res) -> Callback in
            res.bodyString = self.completer.project.projectFile.path
            return .Send
        }
        
        self.server.get("/files") { (req, res) -> Callback in
            let files = self.completer.sourceFiles()
            guard let jsonFiles = try? NSJSONSerialization.dataWithJSONObject(files, options: NSJSONWritingOptions.PrettyPrinted)
                else {
                    self.jsonError(res, message: "Could not generate file list")
                    return .Send
            }
            res.body = jsonFiles
            return .Send
        }
        
        self.server.get("/complete") { req, res in
            
            guard let offset = req.headers["X-Offset"].flatMap({ Int($0)})
                else {
                    self.jsonError(res, message: "Need X-Offset as completion offset for completion")
                    return .Send
            }
            
            guard let path = req.headers["X-Path"] 
                else {
                    self.jsonError(res, message: "Need X-Path as path to the temporary buffer")
                    return .Send
                }

            print("[HTTP] GET /complete X-Offset:\(offset) X-Path:\(path)")
            res.headers["Content-Type"] = "text/json"
            
            let url = NSURL(fileURLWithPath: path)
            let result = self.completer.complete(url, offset: offset)

            switch result {
            case .Success(result: _):
                res.bodyString = result.asJSONString()
                return .Send
            case .Failure(message: let msg):
                self.jsonError(res, message: msg)
                return .Send
            }
        }
    }

    func start() {
        // make sure the server started properly
        var started = true
        do {
            print("[INFO] Listening on port: \(port)")
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                sleep(1)
                if started == true {
                    print("[INFO] Started")
                }
            })
            try server.serveHTTP(port: port, forever: true)
        } catch {
            started = false
            print("[ERR] Server start failed \(error)")
        }
    }
    
    private func jsonError(res: Taylor.Response,
                           message: String,
                           status: HTTPStatus = .BadRequest) {
        res.bodyString = "{\"error\": \"\(message)\"}"
        res.setError(status)
    }
    
}
