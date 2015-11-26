import Foundation

extension SequenceType {
    public func every(predicate: (Self.Generator.Element) -> Bool) -> Bool {
        return self.reduce(true) { (a, e) in a && predicate(e) }
    }
}
