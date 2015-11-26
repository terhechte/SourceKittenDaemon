import Foundation

enum SourceKittenDaemonError: CustomStringConvertible {
    /// One or more argument was invalid.
    case InvalidArgument(description: String)
    case Project(ProjectError)
    case Unknown
    
    /// An error message corresponding to this error.
    var description: String {
        switch self {
        case .InvalidArgument(let description): return description
        case .Project(let e): return e.description
        default: return "An unknown error occured"
        }
    }
}
