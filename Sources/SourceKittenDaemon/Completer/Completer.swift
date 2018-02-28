//
//  Completer.swift
//  SourceKittenDaemon
//
//  Created by Benedikt Terhechte on 12/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation
import SourceKittenFramework

#if os(Linux)
import FileSystemWatcher
#endif

private func pingSKD() {
    NotificationCenter.default.post(name: Notification.Name(rawValue: "skdrefresh"), object: nil)
}

class FileSystemEventsWrapper {


    #if os(Linux)

        func pingAux(event: FileSystemEvent) {
            pingSKD()
        }

        let myWatcher : FileSystemWatcher

        public init(delay: Int, paths toWatch: [String]) {

            myWatcher = FileSystemWatcher(deferringDelay: Double(delay))

            myWatcher.watch(
                paths: toWatch, 
                for: [FileSystemEventType.inAllEvents],
                thenInvoke: pingAux)

            myWatcher.start()
        }

        deinit {
            myWatcher.stop()
        }
            
    #else

        let eventStream: FSEventStreamRef

        public init(delay: Int, paths toWatch: [String]) {

            self.eventStream = FSEventStreamCreate(
                kCFAllocatorDefault, { (_, _, _, _, _, _)  in
                    pingSKD()
                },
                nil,
                toWatch as CFArray,
                FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                CFTimeInterval(delay),
                FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer))!
          
            let runLoop = RunLoop.main

            FSEventStreamScheduleWithRunLoop(eventStream,
                                             runLoop.getCFRunLoop(),
                                             RunLoopMode.defaultRunLoopMode as CFString)
            
            FSEventStreamStart(eventStream)
        }

        deinit {
            FSEventStreamInvalidate(eventStream)
        }

    #endif 

}

/**
This keeps the connection to the XPC via SourceKitten and is being called
from the Completion Server to perform completions. */
class Completer {
    
    // The project parser
    var project: Project

    // Need to monitor changes to the .pbxproject and re-fetch
    // project settings.
    let fsEventWrapper : FileSystemEventsWrapper
    
    init(project: Project) {
        self.project = project
      
        self.fsEventWrapper = FileSystemEventsWrapper(delay: 2, paths: [project.projectFile.path])

        print("[INFO] Monitoring \(project.projectFile.path) for changes")
        NotificationCenter.default.addObserver(
          forName: NSNotification.Name(rawValue: "skdrefresh"), object: nil, queue: nil) { _ in
            print("[INFO] Refreshing project due to change in: \(project.projectFile.path)")
            do { try self.refresh() }
            catch (let e as CustomStringConvertible) { print("[ERR] Refresh failed: \(e.description)") }
            catch (_) { print("[ERR] Refresh failed: unknown reason") }
        }
    }

    deinit {
        
    }

    func refresh() throws {
        self.project = try project.reissue()
    }
    
    func complete(_ url: URL, offset: Int) -> CompletionResult {
        let path = url.path

        guard let file = File(path: path) 
            else { return .failure(message: "Could not read file") }

        let frameworkSearchPaths: [String] = project.frameworkSearchPaths.reduce([]) { $0 + ["-F", $1] }
        let customSwiftCompilerFlags: [String] = project.customSwiftCompilerFlags

        let preprocessorFlags: [String] = project.gccPreprocessorDefinitions
            .reduce([]) { $0 + ["-Xcc", "-D\($1)"] }

        let sourceFiles: [String] = self.sourceFiles()

        // Ugly mutation because `[] + [..] + [..] + [..]` = 'Too complex to solve in reasonable time'
        var compilerArgs: [String] = []
        compilerArgs = compilerArgs + ["-module-name", project.moduleName]
        compilerArgs = compilerArgs + ["-sdk", project.sdkRoot]

        if let platformTarget = project.platformTarget
            { compilerArgs = compilerArgs + ["-target", platformTarget] }

        compilerArgs = compilerArgs + frameworkSearchPaths
        compilerArgs = compilerArgs + customSwiftCompilerFlags
        compilerArgs = compilerArgs + preprocessorFlags
        compilerArgs = compilerArgs + ["-c"]
        compilerArgs = compilerArgs + [path]
        compilerArgs = compilerArgs + ["-j4"]
        compilerArgs = compilerArgs + sourceFiles

        let contents = file.contents
        let request = Request.codeCompletionRequest(
                          file: path,
                          contents: contents,
                          offset: Int64(offset),
                          arguments: compilerArgs)
      
        let response = CodeCompletionItem.parse(response: request.send())
        
        return .success(result: response)
    }
    
    func sourceFiles() -> [String] {
        return project.sourceObjects
            .map({ (o: ProjectObject) -> String? in o.relativePath.absoluteURL(forProject: project)?.path })
                                    .filter({ $0 != nil }).map({ $0! })
    }
    
}
