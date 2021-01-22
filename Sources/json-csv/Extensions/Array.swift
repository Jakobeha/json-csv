//
// Created by Jakob Hain on 11/24/20.
// Copyright (c) 2020 Jakobeha. All rights reserved.
//

import Foundation

extension Array {
    mutating func padTo(minCount: Int, filler: Element) {
        while count < minCount {
            append(filler)
        }
    }
}