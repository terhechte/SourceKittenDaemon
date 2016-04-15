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
                        scheme: options.scheme.isEmpty ? nil : options.scheme,
                        target: options.target.isEmpty ? nil : options.target,
                        configuration: options.configuration)

                let server = CompletionServer(project: project, port: options.port)
                server.start()

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
    let scheme: String
    let target: String
    let configuration: String
    let port: Int

    static func create
    (project: String)
    (scheme: String)
    (target: String)
    (configuration: String)
    (port: Int) -> ServerStartCompleteOptions {
        return self.init(project: project,
                         scheme: scheme,
                         target: target,
                         configuration: configuration,
                         port: port)
    }

    static func evaluate(m: CommandMode)
    -> Result<ServerStartCompleteOptions, CommandantError<SourceKittenDaemonError>> {
        return create
        <*> m <| Option(key: "project",
                        defaultValue: "",
                        usage: "Xcode project to run on")

        <*> m <| Option(key: "scheme",
                        defaultValue: "",
                        usage: "The scheme in the project that should be compiled for")

        <*> m <| Option(key: "target",
                        defaultValue: "",
                        usage: "The target to build")

        <*> m <| Option(key: "configuration",
                        defaultValue: "Debug",
                        usage: "The configuration to use")

        <*> m <| Option(key: "port",
                        defaultValue: 8081,
                        usage: "The port to start on")
    }

}
