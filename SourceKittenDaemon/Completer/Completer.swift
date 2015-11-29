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
class Completer {
    
    // The project parser
    private let project: Project
    
    init(project: Project) {
        self.project = project
    }
    
    func complete(url: NSURL, offset: Int) -> CompletionResult {
        
        guard let path = url.path
            else { return .Failure(message: "Could not resolve file") }

        guard let file = File(path: path) 
            else { return .Failure(message: "Could not read file") }

        let sourceFiles: [String] = project.sourceObjects
          .map({ (o: ProjectObject) -> String? in o.relativePath.absoluteURL(forProject: project)?.path })
          .filter({ $0 != nil }).map({ $0! })
        let customSwiftCompilerFlags: [String] = project.customSwiftCompilerFlags
        let preprocessorFlags: [String] = project.gccPreprocessorDefinitions
            .reduce([]) { $0 + ["-Xcc", "-D\($1)"] }

        var compilerArgs: [String] = []
        compilerArgs = compilerArgs + ["-module-name", project.moduleName]
        compilerArgs = compilerArgs + ["-sdk", project.sdkRoot]
        compilerArgs = compilerArgs + ["-c", path]
        compilerArgs = compilerArgs + ["-j4"]
        compilerArgs = compilerArgs + customSwiftCompilerFlags
        compilerArgs = compilerArgs + preprocessorFlags
        compilerArgs = compilerArgs + sourceFiles

        let contents = file.contents
        let request = Request.CodeCompletionRequest(
                          file: path,
                          contents: contents,
                          offset: Int64(offset),
                          arguments: compilerArgs)
      
        let response = CodeCompletionItem.parseResponse(request.send())
        
        return .Success(result: response)
    }
    
}
