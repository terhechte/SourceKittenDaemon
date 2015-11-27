import Foundation

enum ProjectError : ErrorType, CustomStringConvertible {
    case ProjectNotFound(String)
    case NoValidTarget
    case CouldNotParseProject

    var description: String {
        switch self {
        case .ProjectNotFound(let s): return "Project in `\(s)` not found"
        case .NoValidTarget: return "No valid target found"
        case .CouldNotParseProject: return "Could not parse project"
        }
    }
}
