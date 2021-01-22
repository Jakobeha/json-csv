//
// Created by Jakob Hain on 11/24/20.
// Copyright (c) 2020 Jakobeha. All rights reserved.
//

import Foundation

enum DecodeJsonError: Error {
    case badColumnHeader(String)
    case missingSubArrayIndex(Int)

    var localizedDescription: String {
        switch (self) {
        case .badColumnHeader(let columnHeader):
            return "bad column header (must be an upgrade path): \(columnHeader)"
        case .missingSubArrayIndex(let index):
            return "gaps in sub-array indices, missing: \(index)"
        }
    }
}