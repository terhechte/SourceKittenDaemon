//
//  ServerCommand.swift
//  SourceKittenDaemon
//
//  Created by Benedikt Terhechte on 12/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Commandant
import Foundation
import Result
import SourceKittenFramework
import SwiftXPC

/**
This parses the commandline args and starts the server
*/
struct ServerStartCommand: CommandType {
    let verb = "start"
    let function = "Start the Completion Server"

    func run(mode: CommandMode) -> Result<(), CommandantError<SourceKittenDaemonError>> {
        return ServerStartCompleteOptions.evaluate(mode).flatMap { options in
            
            let project: ProjectType
            
            switch (options.project.isEmpty,
                options.workspace.isEmpty,
                options.folder.isEmpty) {
            case (true, true, true):
                return .Failure(.CommandError(.InvalidArgument(description: "Need either project, workspace, or folder")))
            case (false, true, true):
                project = ProjectType.Project(project: options.project)
            case (true, false, true):
                project = ProjectType.Workspace(workspace: options.workspace)
            case (false, false, true):
                project = ProjectType.Folder(path: options.folder)
            default:
                return .Failure(.CommandError(.InvalidArgument(description: "Need either project, workspace, or folder")))
            }
            
            guard let parser = XcodeParser(project: project,
                targetName: options.target.isEmpty ? nil : options.target)
                else {
                return .Failure(.CommandError(.InvalidArgument(description: "Could not create project parser for \(project.path())")))
            }
            
            let completer = Completer(parser: parser)
            
            CompletionServer.serve(completer, port: options.port)
            
            return .Success()
        }
    }
}

struct ServerStartCompleteOptions: OptionsType {
    let project: String
    let workspace: String
    let folder: String
    let target: String
    let port: Int

    static func create(project: String)(workspace: String)(folder: String)(target: String)(port: Int) -> ServerStartCompleteOptions {
        return self.init(project: project, workspace: workspace, folder: folder, target: target, port: port)
    }

    static func evaluate(m: CommandMode) -> Result<ServerStartCompleteOptions, CommandantError<SourceKittenDaemonError>> {
        return create
            <*> m <| Option(key: "project", defaultValue: "", usage: "Xcode project to run on")
            <*> m <| Option(key: "workspace", defaultValue: "", usage: "Xcode Workspace to run on")
            <*> m <| Option(key: "folder", defaultValue: "", usage: "Swift code folder to run in")
            <*> m <| Option(key: "target", defaultValue: "", usage: "The target in the project that should be compiled for")
            <*> m <| Option(key: "port", defaultValue: 8081, usage: "The port to start on")
    }
}
