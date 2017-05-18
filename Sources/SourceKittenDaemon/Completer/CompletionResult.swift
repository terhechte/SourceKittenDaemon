import Foundation
import SourceKittenFramework

internal enum CompletionResult {
    case success(result: [CodeCompletionItem])
    case failure(message: String)
    
    func minifyValue(_ dic: Dictionary<String, Any>) -> Dictionary<String, Any> {
        return [
            "name" : dic["name"] ?? "",
            "sourcetext" : dic["sourcetext"] ?? "",
        ]
    }

    func asJSON() -> Data? {
        guard case .success(let result) = self,
            let json = try? JSONSerialization.data(withJSONObject: result.map { minifyValue($0.dictionaryValue) }, options: .prettyPrinted)
            else { return nil }
        return json
    }
    
    func asJSONString() -> String? {
        guard let data = self.asJSON() else { return nil }
        Cache.writeTo(data)
        return String(data: data, encoding: String.Encoding.utf8)
    }
}
