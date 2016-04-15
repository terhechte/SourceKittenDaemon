import Foundation
import SourceKittenFramework

internal enum CompletionResult {
    case Success(result: [CodeCompletionItem])
    case Failure(message: String)
    
    func asJSON() -> NSData? {
        guard case .Success(let result) = self,
            let json = try? NSJSONSerialization.dataWithJSONObject(result.map { $0.dictionaryValue }, options: .PrettyPrinted)
            else { return nil }
        return json
    }
    
    func asJSONString() -> String? {
        guard let data = self.asJSON() else { return nil }
        return String(data: data, encoding: NSUTF8StringEncoding)
    }
}
