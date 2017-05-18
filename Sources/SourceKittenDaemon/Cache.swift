
import Foundation
import SourceKittenFramework

typealias CompType = [CodeCompletionItem]

// cache 10 result
class Cache {
    let cacheSize = 5
    private var caches: [String: [CodeCompletionItem]] = [:]
    private var keyArray: [String] = []
    func getKey(offset:String, path:String, cacheKey:String) -> String {
        if cacheKey == "." || cacheKey == "(" {
            return ""
        }
        return "\(path)+\(cacheKey)"
    }
    func getCache(with key: String) -> [CodeCompletionItem]? {
        if key == "" {
            return nil
        }
        return self.caches[key]
    }
    func setCache(_ result: [CodeCompletionItem], for key: String) {
        if key == "" {
            return
        }
        if self.caches.count >= cacheSize {
            let oldKey = self.keyArray.removeFirst()
            print("caches if full; remove at \(oldKey)")
            self.caches.removeValue(forKey: oldKey)
        }
        self.keyArray.append(key)
        self.caches[key] = result
    }

    static func classify(_ completions: CompType) -> CompType {

        print("----> total: \(completions.count)")

        var thisModuleSuperClassComps: CompType = []
        var UIKitSuperClassComps: CompType = []
        var FoundationSuperClassComps: CompType = []
        var thisClassComps: CompType = []
        var otherComps: CompType = []
        completions.forEach { item in
            guard let context = item.dictionaryValue["context"] as? String,
                let moduleName = item.dictionaryValue["moduleName"] as? String
                else { return }
            if context.hasSuffix("thisclass") {
                thisClassComps.append(item)
            } else if context.hasSuffix("thismodule") {
                thisModuleSuperClassComps.append(item)
            } else if moduleName.hasPrefix("UIKit") {
                UIKitSuperClassComps.append(item)
            } else if moduleName.hasPrefix("Foundation") {
                FoundationSuperClassComps.append(item)
            } else {
                otherComps.append(item)
            }
        }
        print("----> inner class: \(thisClassComps.count)")
        print("----> this Module: \(thisModuleSuperClassComps.count)")
        print("----> super UIKit: \(UIKitSuperClassComps.count)")
        print("----> super Foundation: \(FoundationSuperClassComps.count)")
        print("----> super other: \(otherComps.count)")

        return thisClassComps + thisModuleSuperClassComps + UIKitSuperClassComps + FoundationSuperClassComps + otherComps
    }

    static func writeTo(_ data: Data) {

        return

        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("com.djl.txt")
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            if FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil) {
                print("create snippet file: \(fileURL.path)")
            }
        } else {
            print("exist snippet file: \(fileURL.path)")
        }
        try? data.write(to: fileURL)
    }
}



/*
[{
    "descriptionKey" : "attempt(operation: (Int) -> Result<(), NoError>)",
    "kind" : "source.lang.swift.decl.function.method.instance",
    "name" : "attempt(operation:)",
    "sourcetext" : "attempt(operation: <#T##(Int) -> Result<(), NoError>#>)",
    "numBytesToErase" : 0,
    "typeName" : "SignalProducer<Int, NoError>",
    "docBrief" : "Apply operation to values from self with successful results forwarded on the returned producer and failures sent as failed events.",
    "associatedUSRs" : "s:FE13ReactiveSwiftPS_22SignalProducerProtocol7attemptFT9operationFwx5ValueGO6Result6ResultT_wx5Error__GVS_14SignalProducerwxS1_wxS4__",
    "moduleName" : "ReactiveSwift",
    "context" : "source.codecompletion.context.superclass"
}]
*/
