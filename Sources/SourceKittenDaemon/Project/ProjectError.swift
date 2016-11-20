import Foundation

public enum ProjectError : Error, CustomStringConvertible {
    case projectNotFound(String)
    case noValidTarget
    case couldNotParseProject

    public var description: String {
        switch self {
        case .projectNotFound(let s): return "Project in `\(s)` not found"
        case .noValidTarget: return "No valid target found"
        case .couldNotParseProject: return "Could not parse project"
        }
    }
}
