//
//  Extensions.swift
//  Xcode
//
//  Created by Tom Lokhorst on 2015-08-29.
//  Copyright © 2015 nonstrict. All rights reserved.
//

import Foundation

func += <KeyType, ValueType> (inout left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
  for (k, v) in right {
    left.updateValue(v, forKey: k)
  }
}

extension SequenceType {
  func ofType<T>(type: T.Type) -> [T] {
    return self.flatMap { $0 as? T }
  }

  func any(pred: Generator.Element -> Bool) -> Bool {
    for elem in self {
      if pred(elem) {
        return true
      }
    }

    return false
  }

  func groupBy<Key: Hashable>(keySelector: Generator.Element -> Key) -> [Key : [Generator.Element]] {
    var groupedBy = Dictionary<Key, [Generator.Element]>()

    for element in self {
      let key = keySelector(element)
      if let group = groupedBy[key] {
        groupedBy[key] = group + [element]
      } else {
        groupedBy[key] = [element]
      }
    }

    return groupedBy
  }

  func sortBy<U: Comparable>(keySelector: Generator.Element -> U) -> [Generator.Element] {
    return self.sort { keySelector($0) < keySelector($1) }
  }
}