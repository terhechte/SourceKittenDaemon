import Foundation

extension Path {

    func absoluteURL(forProject project: Project) -> NSURL? {
        switch self {
        case .Absolute(let path):
            return NSURL(fileURLWithPath: path).URLByStandardizingPath
        case .RelativeTo(.SourceRoot, let path):
            return project.srcRoot.URLByAppendingPathComponent(path).URLByStandardizingPath
        case .RelativeTo(_, let path):
            return NSURL(fileURLWithPath: path).URLByStandardizingPath
        }
    }
    
}
