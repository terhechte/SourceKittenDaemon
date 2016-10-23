import Foundation
import SourceKittenFramework

internal enum CompletionResult {
    case success(result: [CodeCompletionItem])
    case failure(message: String)
    
    func asJSON() -> Data? {
        guard case .success(let result) = self,
            let json = try? JSONSerialization.data(withJSONObject: result.map { $0.dictionaryValue }, options: .prettyPrinted)
            else { return nil }
        return json
    }
    
    func asJSONString() -> String? {
        guard let data = self.asJSON() else { return nil }
        return String(data: data, encoding: String.Encoding.utf8)
    }
}
