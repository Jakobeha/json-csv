//
// Created by Jakob Hain on 12/4/20.
// Copyright (c) 2020 Jakobeha. All rights reserved.
//

import Foundation

struct Csv: LosslessStringConvertible {
    static let separator: Character = ";"
    static let columnOrder: [String] = [
        "name",
        "description",
        "view",
        "cost",
        "type",
        "kind",
        "terrains",
        "radius",
        "fireRate",
        "maxInaccuracy",
        "turnSpeed",
        "availableTargetModes",
        "projectile",
        "numProjectiles",
        "angleBetweenProjectiles",
        "children",

        "iron",
        "gold",
        "coal",
        "copper",
        "aluminum",
        "lead",
        "uranium",

        "damage",
        "dps",
        "fractionDamage",
        "fractionDps",
        "blastRadius",
        "explosionView",
        "pierce",
        "maxTravelDistance",
        "speed",
        "size",
        "width",
        "initialWidth",
        "widthPerTile",
        "effects",

        "damageMultiplier",
        "speedMultiplier",
        "distancePerSecond",
        "duration",
        "isDeep"
    ]

    static func shouldProcessEntry(header: String) -> Bool {
        !header.isEmpty && !header.hasPrefix("#")
    }

    var columns: [[String]]

    init(name: String, rowHeaders: [String], columns: [String:[String]]) {
        let sortedColumns = columns.sorted { lhs, rhs in
            let columnHeaderLhs = lhs.key
            let columnHeaderRhs = rhs.key
            let columnHeaderComponentsLhs = columnHeaderLhs.split(separator: ".")
            let columnHeaderComponentsRhs = columnHeaderRhs.split(separator: ".")
            for (columnHeaderComponentLhsSubsequence, columnHeaderComponentRhsSubsequence) in zip(columnHeaderComponentsLhs, columnHeaderComponentsRhs) {
                let columnHeaderComponentLhs = String(columnHeaderComponentLhsSubsequence)
                let columnHeaderComponentRhs = String(columnHeaderComponentRhsSubsequence)

                let componentComparison: Int
                if Csv.columnOrder.contains(columnHeaderComponentLhs) && Csv.columnOrder.contains(columnHeaderComponentRhs) {
                    componentComparison = Csv.columnOrder.firstIndex(of: columnHeaderComponentLhs)! - Csv.columnOrder.firstIndex(of: columnHeaderComponentRhs)!
                } else if Csv.columnOrder.contains(columnHeaderComponentLhs) {
                    componentComparison = ComparisonResult.orderedAscending.rawValue
                } else if Csv.columnOrder.contains(columnHeaderComponentRhs) {
                    componentComparison = ComparisonResult.orderedDescending.rawValue
                } else if Int(columnHeaderLhs) != nil && Int(columnHeaderRhs) != nil {
                    componentComparison = Int(columnHeaderLhs)! - Int(columnHeaderRhs)!
                } else {
                    componentComparison = columnHeaderLhs.compare(columnHeaderRhs).rawValue
                }

                if componentComparison < 0 {
                    return true
                } else if componentComparison > 0 {
                    return false
                }
            }

            // We will probably never get to this point
            return columnHeaderComponentsLhs.count < columnHeaderComponentsRhs.count
        }.map { (columnHeader, column) in
            [columnHeader] + column
        }

        self.columns = [[name] + rowHeaders] + sortedColumns
    }

    init(_ description: String) {
        columns = description.split(separator: "\n", omittingEmptySubsequences: false).map {
            $0.split(separator: Csv.separator, omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
        }.transposed
    }

    var name: String? {
        if columns.isEmpty || columns[0].isEmpty {
            return nil
        } else {
            return columns[0][0]
        }
    }

    var headers: ArraySlice<String> {
        if columns.isEmpty || columns[0].isEmpty {
            return []
        } else {
            return columns[0].dropFirst()
        }
    }

    /// We would use [String:ArraySlice<String>], but for some reason indexing the array slice causes a segfault
    var fields: [String:[String]] {
        if columns.isEmpty {
            return [:]
        } else {
            return [String:[String]](uniqueKeysWithValues: columns.dropFirst().filter {
                !$0.isEmpty && Csv.shouldProcessEntry(header: $0[0])
            }.map {
                ($0[0], Array($0.dropFirst()))
            })
        }
    }

    func fieldsAt(index: Int) -> [String:String] {
        fields.mapValues {
            if index < $0.count {
                return $0[index]
            } else {
                return ""
            }
        }
    }

    var description: String {
        columns.transposed.map { $0.joined(separator: "\(Csv.separator) ") }.joined(separator: "\n")
    }

    func write(to url: URL, atomically: Bool) throws {
        try description.write(to: url, atomically: atomically, encoding: .utf8)
    }
}