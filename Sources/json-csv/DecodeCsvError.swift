//
// Created by Jakob Hain on 11/24/20.
// Copyright (c) 2020 Jakobeha. All rights reserved.
//

import Foundation

enum DecodeCsvError: Error {
    case wrongType(expected: Any.Type, actual: Type)
    case wrongTypeMultipleOptions(expecteds: [Type], actual: Type)
    case encounteredLiteralUnknown

    var localizedDescription: String {
        switch (self) {
        case .wrongType(let expected, let actual):
            return "wrong type: expected \(expected), got \(actual)"
        case .wrongTypeMultipleOptions(let expecteds, let actual):
            return "wrong type: expected any of \(expecteds), got \(actual)"
        case .encounteredLiteralUnknown:
            return "encountered a literal 'unknown' in JSON. Use 'null' instead"
        }
    }
}