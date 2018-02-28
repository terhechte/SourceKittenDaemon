//
//  StartCommand.swift
//  sourcekittend
//
//  Created by Benedikt Terhechte on 12/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Commandant
import Foundation
import Result
import SourceKittenFramework
import SourceKittenDaemon

/**
This parses the commandline args and starts the server
*/
struct StartCommand: CommandProtocol {

    let verb = "start"
    let function = "Start the completion server"

    func run(_ options: StartOptions) -> Result<(), CommandError> {
        if options.project.isEmpty {
            return .failure(.invalidArgument(
                description: "Please provide a project"))
        }

        do {
            let type = ProjectType.project(project: options.project)
            let project = try Project(
              type: type,
              scheme: options.scheme.isEmpty ? nil : options.scheme,
              target: options.target.isEmpty ? nil : options.target,
              configuration: options.configuration)

            do {
                let server = try CompletionServer(project: project, port: options.port)
                try server.start()
                return .success()
            } catch let error {
                return Result.failure(CommandError.other(error))
            }
        } catch (let e as ProjectError) {
            return .failure(.project(e))
        } catch (_) {
            return .failure(.unknown)
        }
    }
}

struct StartOptions: OptionsProtocol {

    let project: String
    let scheme: String
    let target: String
    let configuration: String
    let port: Int

    static func create(project: String) -> (String) -> (String) -> (String) -> (Int) -> StartOptions {
        return { scheme in { target in { configuration in { port in
            return self.init(project: project,
                             scheme: scheme,
                             target: target,
                             configuration: configuration,
                             port: port)
            }}}}
    }

    static func evaluate(_ m: CommandMode) -> Result<StartOptions, CommandantError<CommandError>> {
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

enum CommandError: Error, CustomStringConvertible {

    /// One or more argument was invalid.
    case invalidArgument(description: String)
    case project(ProjectError)
    case unknown
    case other(Error)

    /// An error message corresponding to this error.
    var description: String {
        switch self {
        case .invalidArgument(let description): return description
        case .project(let e): return e.description
        case .other(let e): return "\(e)"
        default: return "An unknown error occured"
        }
    }
}
