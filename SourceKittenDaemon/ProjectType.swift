import Foundation
import SourceKittenFramework

/// Represents a 'project'.
/// This can be an xcodeproj, workspace or something else.
/// It works with the path naively, therefore the caller is responsible
/// for validating the given project actually exists.
internal enum ProjectType {
    case Project(project: String)
    case Workspace(workspace: String)
    case Folder(path: String)
    
    func projectDir() -> String {
        switch self {
        case .Folder(let s):  return s
        default: return (path() as NSString).stringByDeletingLastPathComponent
        }
    }
    
    func projectFileURL() -> NSURL? {
        switch self {
        case .Project: return NSURL(fileURLWithPath: path(), isDirectory: true)
        // @TODO : implement folder and workspace support. This involves looking for
        // nested .xcodeproj's but workspaces will have to somehow support multiple .xcodeproj's
        case .Folder: fatalError("Folder projects not supported yet")
        case .Workspace: fatalError("Workspace projects not supported yet")
        }
    }
    
    private func path() -> String {
        switch self {
        case .Project(project: let s):
            return s
        case .Workspace(workspace: let s):
            return s
        case .Folder(path: let s):
            return s
        }
    }

}
