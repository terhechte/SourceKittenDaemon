//
//  Completer.swift
//  SourceKittenDaemon
//
//  Created by Benedikt Terhechte on 12/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation
import SourceKittenFramework
import SwiftXPC

/**
This keeps the connection to the XPC via SourceKitten and is being called
from the Completion Server to perform completions. */
internal class Completer {
    
    // The Base path to the .xcodeproj / workspace
    private let baseProject: ProjectType
    
    // The project parser
    private let parser: XcodeParser
    
    internal init(project: ProjectType, parser: XcodeParser) {
        self.baseProject = project
        self.parser = parser
    }
    
    internal func complete(filePath: String, fileInProject: String, offset: Int) -> CompletionResult {
        
        let path = filePath.absolutePathRepresentation()
        let contents: String
        if let file = File(path: path) {
            contents = file.contents
        } else {
            return .Failure(message: "Could not read file")
        }
        
        // create compiler args, remove the current file
        let compilerArgs = ["-c", path] +
                           ["-sdk", sdkPath()] +
                           parser.projectPaths({ $0 == fileInProject })
      
        let request = Request.CodeCompletionRequest(
                          file: path,
                          contents: contents,
                          offset: Int64(offset),
                          arguments: compilerArgs)
      
        let response = CodeCompletionItem.parseResponse(request.send())
        
        return .Success(result: response)
    }
    
}
