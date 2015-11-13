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
Simple wrapper around an Xcode project. Can be a 
- Project (.xcodeproj)
- Workspace (.xcworkspace)
- Folder (future / linux)
Where a folder has to have some sort of other compile infrastructure. I've
just included it for completeness' sake
*/
enum ProjectType {
    case Project(project: String)
    case Workspace(workspace: String)
    case Folder(path: String)
    
    func folderPath() -> String {
        if case .Folder(let f) = self { return f }
        return (self.path() as NSString).stringByDeletingLastPathComponent
    }
    
    func path() -> String {
        switch self {
        case .Project(project: let s):
            return s
        case .Workspace(workspace: let s):
            return s
        case .Folder(path: let s):
            return s
        }
    }
    
    func pbxProject() -> String? {
        let fileManager = NSFileManager.defaultManager()
        let pbxFile = (self.path() as NSString).stringByAppendingPathComponent("project.pbxproj")
        if !fileManager.fileExistsAtPath(pbxFile) { return nil }
        
        return pbxFile
    }
}

enum CompletionResult {
    case Success(result: [CodeCompletionItem])
    case Failure(message: String)
    
    func asJSON() -> NSData? {
        guard case .Success(let result) = self,
            let json = try? NSJSONSerialization.dataWithJSONObject(result.map { $0.dictionaryValue }, options: .PrettyPrinted)
            else { return nil }
        return json
    }
    
    func asJSONString() -> String? {
        guard let data = self.asJSON() else { return nil }
        return String(data: data, encoding: NSUTF8StringEncoding)
    }
}

/**
This keeps the connection to the XPC via SourceKitten and is being called
from the Completion Server to perform completions. */
class Completer {
    
    // The Arguments for XPC, i.e. SDK, Frameworks
    let compilerArgs: [String]
    
    // The Base path to the .xcodeproj / workspace
    let baseProject: ProjectType
    
    init(project: ProjectType, parser: XcodeParser) {
        self.baseProject = project
        self.compilerArgs = ["-c", project.folderPath(), "-sdk", sdkPath()]
        // FIXME: Parse the project, and get more info
    }
    
    /**
    FIXME: We're probably giving all projects files via compilerArgs to 
    sourcekitd. `filePath` will contain a temporary buffer copy of one of
     the files we're already givin in via the compilerArgs. So, here we also
     need the original filename of the file being completed, so we can remove
     it from the compiler args, so we don't get duplicate symbols
    */
    func complete(filePath: String, offset: Int, completion: (result: CompletionResult) -> ()) {
        
        let path = filePath.absolutePathRepresentation()
        let contents: String
        if let file = File(path: path) {
            contents = file.contents
        } else {
            completion(result: .Failure(message: "Could not read file"))
            return
        }
        
        let request = Request.CodeCompletionRequest(file: path, contents: contents,
            offset: Int64(offset),
            arguments: self.compilerArgs)
        
        let response = CodeCompletionItem.parseResponse(request.send())
        
        completion(result: .Success(result: response))
    }
    
}