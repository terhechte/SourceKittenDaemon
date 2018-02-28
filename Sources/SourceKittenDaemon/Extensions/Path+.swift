import Foundation
import XcodeEdit

extension Path {

    func absoluteURL(forProject project: Project) -> URL? {
        switch self {
        case .absolute(let path):
            return URL(fileURLWithPath: path).standardizedFileURL
        case .relativeTo(.sourceRoot, let path):
            return  project.srcRoot.appendingPathComponent(path).standardizedFileURL
        case .relativeTo(_, let path):
            return URL(fileURLWithPath: path).standardizedFileURL
        }
    }

}
