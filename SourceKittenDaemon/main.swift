//
//  main.swift
//  SourceKittenDaemon
//
//  Created by Benedikt Terhechte on 12/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Cocoa
import Commandant
import Result

internal enum SourceKittenDaemonError: CustomStringConvertible {
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

@objc class TimerDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(notification: NSNotification) {
        
    }
}

/**
This is currently the only way I could think of to allow unit tests.
This command will run the app like a cocoa app, so that unit tests
can be run.
There may be a different way with arcane unit test xcode knowledge, but cursory
 googling did not yield anything worthwhile.
*/
struct ServerTestCommand: CommandType {
    let verb = "test"
    let function = "mock command for running the test suite"
    
    func run(mode: CommandMode) -> Result<(), CommandantError<SourceKittenDaemonError>> {
        let delegate = TimerDelegate()
        
        let app = NSApplication.sharedApplication()
        app.delegate = delegate
        app.run()
        
        return .Success(())
    }
}

let registry = CommandRegistry<SourceKittenDaemonError>()
registry.register(ServerStartCommand())

registry.register(ServerTestCommand())

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)


registry.main(defaultVerb: "help") { error in
    fputs("\(error)\n", stderr)
}


