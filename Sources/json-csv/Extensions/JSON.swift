//
// Created by Jakob Hain on 5/12/20.
// Copyright (c) 2020 Jakobeha. All rights reserved.
//

import SpriteKit

extension JSON {
    var isNull: Bool { type == .null }

    func toString() throws -> String {
        try string.orThrow { DecodeCsvError.wrongType(expected: String.self, actual: self.type) }
    }

    func toFloat() throws -> Float {
        try float.orThrow { DecodeCsvError.wrongType(expected: Float.self, actual: self.type) }
    }

    func toDouble() throws -> Double {
        try double.orThrow { DecodeCsvError.wrongType(expected: Double.self, actual: self.type)}
    }

    func toCgFloat() throws -> CGFloat {
        CGFloat(try toFloat())
    }

    func toTimeInterval() throws -> TimeInterval {
        TimeInterval(try toDouble())
    }

    func toInt() throws -> Int {
        try int.orThrow { DecodeCsvError.wrongType(expected: Int.self, actual: self.type) }
    }

    func toUInt8() throws -> UInt8 {
        try uInt8.orThrow { DecodeCsvError.wrongType(expected: UInt8.self, actual: self.type) }
    }

    func toBoolean() throws -> Bool {
        try bool.orThrow { DecodeCsvError.wrongType(expected: Bool.self, actual: self.type) }
    }

    func toArray() throws -> [JSON] {
        try array.orThrow { DecodeCsvError.wrongType(expected: [Any].self, actual: self.type) }
    }

    func toDictionary() throws -> [String:JSON] {
        try dictionary.orThrow { DecodeCsvError.wrongType(expected: [String:Any].self, actual: self.type)}
    }
}
