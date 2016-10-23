//
//  CompletionServer.swift
//  SourceKittenDaemon
//
//  Created by Benedikt Terhechte on 12/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation
import Vapor

/**
This runs a simple webserver that can be queried from Emacs to get completions
for a file.
*/
public class CompletionServer {

    let port: Int
    let completer: Completer

    let droplet = Droplet(arguments: ["vapor", "serve"])

    public init(project: Project, port: Int) {
        self.completer = Completer(project: project)
        self.port = port

        droplet.get("/ping") { request in
            return "OK"
        }

        droplet.get("/project") { request in
            return self.completer.project.projectFile.path
        }

        droplet.get("/files") { request in
            let files = self.completer.sourceFiles()
            guard let jsonFiles = try? JSONSerialization.data(
                    withJSONObject: files,
                    options: JSONSerialization.WritingOptions.prettyPrinted
                  ),
                  let filesString = String(data: jsonFiles, encoding: String.Encoding.utf8) else {
                throw Abort.custom(
                  status: .badRequest,
                  message: "{\"error\": \"Could not generate file list\"}"
                )
            }
            return filesString
        }

        droplet.get("/complete") { request in
            guard let offsetString = request.headers["X-Offset"],
                  let offset = Int(offsetString) else {
                throw Abort.custom(
                  status: .badRequest,
                  message: "{\"error\": \"Need X-Offset as completion offset for completion\"}"
                )
            }

            guard let path = request.headers["X-Path"] else {
                throw Abort.custom(
                  status: .badRequest,
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
                  status: .badRequest,
                  message: "{\"error\": \"\(msg)\"}"
                )
            }
        }
    }

    public func start() {
        droplet.run(servers: ["default": (host: "0.0.0.0", port: port, securityLayer: .none)])
    }

}
