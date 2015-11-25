import Foundation
import SourceKittenFramework

/**
Simple wrapper around an Xcode project. Can be a 
- Project (.xcodeproj)
- Workspace (.xcworkspace)
- Folder (future / linux)
Where a folder has to have some sort of other compile infrastructure. I've
just included it for completeness' sake
*/
internal enum ProjectType {
    case Project(project: String)
    case Workspace(workspace: String)
    case Folder(path: String)
    
    func folderPath() -> String {
        if case .Folder(let f) = self { return f }
        return (self.path() as NSString).stringByDeletingLastPathComponent
    }
    
    func path() -> String {
        switch self {
        case .Project(project: let s):
            return s
        case .Workspace(workspace: let s):
            return s
        case .Folder(path: let s):
            return s
        }
    }

    func xcodeprojURL() -> NSURL? {
        switch self {
        case .Project: return NSURL(fileURLWithPath: path(), isDirectory: true)
        // @TODO : implement folder and workspace support. This involves looking for
        // nested .xcodeproj's but workspaces will have to somehow support multiple .xcodeproj's
        case .Folder: fatalError("Folder projects not supported yet")
        case .Workspace: fatalError("Workspace projects not supported yet")
        }
    }
    
}
