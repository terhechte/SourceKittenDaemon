import Foundation

/// Represents the type of a project including it's path.
/// This can be an xcodeproj, workspace or something else.
/// It works with the path naively, therefore the caller is responsible
/// for validating the given project actually exists.
public enum ProjectType {
    case project(project: String)
    case workspace(workspace: String)
    case folder(path: String)

    public var projectDir: URL? {
        switch self{
        case .folder(let s):  return URL(fileURLWithPath: s)
        default: return (url as NSURL?)?.deletingLastPathComponent?.standardizedFileURL
        }
    }

    public var projectFile: URL? {
        switch self {
        case .project: return url
        // @TODO : implement folder and workspace support. This involves looking for
        // nested .xcodeproj's but workspaces will have to somehow support multiple .xcodeproj's
        case .folder: fatalError("Folder projects not supported yet")
        case .workspace: fatalError("Workspace projects not supported yet")
        }
    }

    public var path: String {
        switch self {
        case .project(project: let s): return s
        case .workspace(workspace: let s): return s
        case .folder(path: let s): return s
        }
    }

    public var url: URL? {
        return URL(fileURLWithPath: path)
    }
}
