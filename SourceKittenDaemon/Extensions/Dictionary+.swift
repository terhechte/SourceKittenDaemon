import Foundation

extension Dictionary {
  mutating func merge(
    dictionary: Dictionary<Key, Value>) {
      for (key, value) in dictionary {
        self[key] = value
      }
  }
}
