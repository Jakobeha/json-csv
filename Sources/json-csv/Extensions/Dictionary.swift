//
// Created by Jakob Hain on 5/4/20.
// Copyright (c) 2020 Jakobeha. All rights reserved.
//

import Foundation

extension Dictionary {
    func mapKeys<Key2>(_ transform: (Key) throws -> Key2) rethrows -> [Key2:Value] {
        [Key2:Value](uniqueKeysWithValues: try map { (key, value) in (try transform(key), value) })
    }

    func mapToDict<Key2, Value2>(_ transform: ((key: Key, value: Value)) throws -> (key: Key2, value: Value2)) rethrows -> [Key2:Value2] {
        [Key2:Value2](uniqueKeysWithValues: try map { keyAndValue in try transform(keyAndValue) })
    }

    mutating func getOrInsert(_ key: Key, getDefault: () throws -> Value) rethrows -> Value {
        if (self[key] == nil) {
            self[key] = try getDefault()
        }
        return self[key]!
    }
}
