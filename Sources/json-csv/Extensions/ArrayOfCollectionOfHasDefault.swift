//
// Created by Jakob Hain on 11/28/20.
// Copyright (c) 2020 Jakobeha. All rights reserved.
//

import Foundation

extension Array where Element: Collection, Element.Index == Int, Element.Element: HasDefault {
    var transposed: [[Element.Element]] {
        let newSize = map { $0.count }.max() ?? 0
        var result = [[Element.Element]](repeating: [Element.Element](repeating: Element.Element.defaultValue, count: count), count: newSize)
        for y in 0..<count {
            let row = self[y]
            for x in 0..<row.count {
                result[x][y] = row[x]
            }
        }
        return result
    }
}
