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
    
    private init(completer: Completer, port: Int) {
        self.port = port
        self.completer = completer
        
        // FIXME: Add parsing to get the requried properties either from 
        // the query string, or from the post args or headers
        self.server = Taylor.Server()
        self.server.get("/") { req, res, callback in
            
            res.headers["Content-Type"] = "text/json"
            
            // FIXME: We need to get in:
            let offset = 45
            let file = ""
            
            self.completer.complete(file, offset: offset, completion: { (result) -> () in
                // FIXME: Taylor changed to a synchronous style. This is still
                // using the old, asynchronous style. Changing this is easy though.
                switch result {
                case .Success(result: _):
                    res.bodyString = result.asJSONString()
                case .Failure(message: let msg):
                    res.bodyString = "{\"error\": \"\(msg)\""
                }
                callback(.Send(req, res))
            })
            
            callback(.Send(req, res))
        }
        
        do {
            print("Staring server on port: \(port)")
            try server.serveHTTP(port: port, forever: true)
        } catch {
            print("Server start failed \(error)")
        }
    }
}