//
//  main.swift
//  SourceKittenDaemon
//
//  Created by Benedikt Terhechte on 12/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation
import Commandant

enum SourceKittenDaemonError: CustomStringConvertible {
    /// One or more argument was invalid.
    case InvalidArgument(description: String)
    
    /// Failed to generate documentation.
    case DocFailed
    
    /// An error message corresponding to this error.
    var description: String {
        switch self {
        case let .InvalidArgument(description):
            return description
        case .DocFailed:
            return "Failed to generate documentation"
        }
    }
}

let registry = CommandRegistry<SourceKittenDaemonError>()
registry.register(ServerStartCommand())

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)

registry.main(defaultVerb: "help") { error in
    fputs("\(error)\n", stderr)
}


