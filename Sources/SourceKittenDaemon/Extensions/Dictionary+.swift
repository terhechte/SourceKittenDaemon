import Foundation

extension Dictionary {
  mutating func merge(
    _ dictionary: Dictionary<Key, Value>) {
      for (key, value) in dictionary {
        self[key] = value
      }
  }
}
