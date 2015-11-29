import Foundation

/// Represents the type of a project including it's path.
/// This can be an xcodeproj, workspace or something else.
/// It works with the path naively, therefore the caller is responsible
/// for validating the given project actually exists.
enum ProjectType {
    case Project(project: String)
    case Workspace(workspace: String)
    case Folder(path: String)

    var projectDir: NSURL? {
        switch self{
        case .Folder(let s):  return NSURL(fileURLWithPath: s)
        default: return url?.URLByDeletingLastPathComponent?.URLByStandardizingPath
        }
    }

    var projectFile: NSURL? {
        switch self {
        case .Project: return url
        // @TODO : implement folder and workspace support. This involves looking for
        // nested .xcodeproj's but workspaces will have to somehow support multiple .xcodeproj's
        case .Folder: fatalError("Folder projects not supported yet")
        case .Workspace: fatalError("Workspace projects not supported yet")
        }
    }

    var path: String {
        switch self {
        case .Project(project: let s): return s
        case .Workspace(workspace: let s): return s
        case .Folder(path: let s): return s
        }
    }

    var url: NSURL? {
        return NSURL(fileURLWithPath: path)
    }
}
