//
// Created by Jakob Hain on 12/4/20.
// Copyright (c) 2020 Jakobeha. All rights reserved.
//

import Foundation

struct ObjectRow {
    var id: String
    var fields: [String:String] = [:]

    func mergeWith(columns: inout [String:[String]], index: Int) {
        for (fieldKey, _) in fields {
            if !columns.keys.contains(fieldKey) {
                columns[fieldKey] = [String](repeating: "", count: index)
            }
        }
        for columnKey in columns.keys {
            let nextColumn = fields[columnKey] ?? ""
            columns[columnKey]!.append(nextColumn)
        }
    }
}