import Foundation

extension Sequence {
    public func every(_ predicate: (Self.Iterator.Element) -> Bool) -> Bool {
        return self.reduce(true) { (a, e) in a && predicate(e) }
    }
}
