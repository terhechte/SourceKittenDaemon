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
            if options.project.isEmpty {
                return .Failure(.CommandError(.InvalidArgument(
                    description: "Please provide a project")))
            }

            do {
                let type = ProjectType.Project(project: options.project)
                let project = try Project(
                        type: type,
                        targetName: options.target.isEmpty ? nil : options.target,
                        configurationName: nil)

                let completer = Completer(project: project)
                CompletionServer.serve(completer, port: options.port)

                return .Success()
            } catch (let e as ProjectError) {
                return .Failure(.CommandError(.Project(e)))
            } catch (_) {
                return .Failure(.CommandError(.Unknown))
            }
        }
    }
}

struct ServerStartCompleteOptions: OptionsType {

    let project: String
    let target: String
    let port: Int

    static func create(project: String)(target: String)(port: Int) -> ServerStartCompleteOptions {
        return self.init(project: project, target: target, port: port)
    }

    static func evaluate(m: CommandMode)
    -> Result<ServerStartCompleteOptions, CommandantError<SourceKittenDaemonError>> {
        return create
        <*> m <| Option(key: "project",
                        defaultValue: "",
                        usage: "Xcode project to run on")

        <*> m <| Option(key: "target",
                        defaultValue: "",
                        usage: "The target in the project that should be compiled for")

        <*> m <| Option(key: "port",
                        defaultValue: 8081,
                        usage: "The port to start on")
    }

}
