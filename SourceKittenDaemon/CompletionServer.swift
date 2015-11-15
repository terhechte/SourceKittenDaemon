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
    
    static func serve(completer: Completer, port: Int) {
        self.singletonServer = CompletionServer(completer: completer, port: port)
    }
    
    private static var singletonServer: CompletionServer? = nil
    
    let server: Taylor.Server
    
    let port: Int
    
    let completer: Completer
    
    internal init(completer: Completer, port: Int) {
        self.port = port
        self.completer = completer
        
        self.server = Taylor.Server()
        self.server.get("/stop") { req, res, callback in
            self.stop()
        }
        
        self.server.get("/complete") { req, res, callback in
            
            res.headers["Content-Type"] = "text/json"
            
            // I'm not sure what's the best place to store the offset, file and original file.
            // Per Rest convention it would probably be a mix of query string and headers,
            // but for simplicities sake, I'll use the headers for now.
            
            guard let offset = req.headers["X-Offset"].flatMap({ Int($0)})
                else {
                    callback(self.jsonError(req, res: res, message: "Need X-Offset as completion offset for completion"))
                    return
            }
            
            guard let path = req.headers["X-Path"]
                else {
                    callback(self.jsonError(req, res: res, message: "Need X-Path as path to the temporary buffer"))
                    return
            }
            
            guard let file = req.headers["X-File"]
                else {
                    callback(self.jsonError(req, res: res, message: "Need X-File as name of the file in the project"))
                    return
            }
            
            let result = self.completer.complete(path, fileInProject: file, offset: offset)
            switch result {
            case .Success(result: _):
                res.bodyString = result.asJSONString()
                callback(.Send(req, res))
            case .Failure(message: let msg):
                self.jsonError(req, res: res, message: msg)
            }
        }
        
        do {
            print("Staring server on port: \(port)")
            try server.serveHTTP(port: port, forever: true)
        } catch {
            print("Server start failed \(error)")
        }
    }
    
    /**
    Awful way of returning an error
    */
    private func jsonError(req: Taylor.Request, res: Taylor.Response, message: String) -> Taylor.Callback {
        res.bodyString = "{\"error\": \"\(message)\"}"
        return Callback.Send(req, res)
    }
    
    /**
    Stop and end the server
    */
    internal func stop() {
        self.server.stopListening()
    }
    
}
