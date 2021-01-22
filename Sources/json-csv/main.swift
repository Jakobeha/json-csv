//
//  main.swift
//  json-csv
//
//  Created by Jakob Hain on 11/24/20.
//  Copyright © 2020 Jakobeha. All rights reserved.
//

import ArgumentParser
import Foundation

struct JsonCsv: ParsableCommand {
    static let configuration = CommandConfiguration(
            abstract: "convert CSV from / to JSON",
            version: "0.0.1",
            subcommands: [JsonToCsvs.self, JsonToCsv.self, CsvsToJson.self, CsvsToJsonSplice.self, CsvToJsonSplice.self, CsvToJson.self]
    )

    struct JsonToCsvs: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "convert a JSON to CSVs")

        @Option(name: .shortAndLong, help: "column format")
        var columnFormat: ColumnFormat = .standard

        @Argument(help: "input JSON")
        var source: URL

        @Argument(help: "output directory of CSVs")
        var destination: URL

        mutating func run() {
            do {
                let json = try JSON(data: try! Data(contentsOf: source))
                let csvs = try JsonToCsvs.convert(json: json, columnFormat: columnFormat)
                for csv in csvs {
                    // CSV that we create will always have a name
                    let csvDestination = destination.appendingPathComponent(csv.name!, isDirectory: false).appendingPathExtension("csv")
                    try csv.write(to: csvDestination, atomically: true)
                }
            } catch {
                log(error: error)
            }
        }

        private static func convert(json: JSON, columnFormat: ColumnFormat) throws -> [Csv] {
            try json.toDictionary().map { (key, elementJson) in
                try JsonToCsv.convertObject(key: key, json: elementJson, columnFormat: columnFormat)
            }
        }

    }

    struct JsonToCsv: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "convert a JSON to a CSV")

        @Option(name: .shortAndLong, help: "column format")
        var columnFormat: ColumnFormat = .standard

        @Argument(help: "input JSON")
        var source: URL

        @Argument(help: "output CSV")
        var destination: URL

        mutating func run() {
            do {
                let json = try JSON(data: try! Data(contentsOf: source))
                let csv = try JsonToCsv.convertObject(key: destination.baseName, json: json, columnFormat: columnFormat)
                try csv.write(to: destination, atomically: true)
            } catch {
                log(error: error)
            }
        }

        static func convertObject(key: String, json: JSON, columnFormat: ColumnFormat) throws -> Csv {
            let rows: [ObjectRow] = try {
                switch (columnFormat) {
                case .standard:
                    return try convertDictOrArrayToDict(json: json).map { (id, objectJson) in
                        try convertObjectRow(id: id, json: objectJson)
                    }
                case .array:
                    return try json.toArray().enumerated().flatMap { (index2, json2) in
                        try json2.toArray().enumerated().flatMap { (index1, json1) in
                            try json1.toArray().enumerated().map { (index0, objectJson) in
                                let id = "\(index0)-\(index1)-\(index2)"
                                return try convertObjectRow(id: id, json: objectJson)
                            } as [ObjectRow]
                        }
                    }
                }
            }()

            let name = key.capitalizedCamelCase
            let rowHeaders = rows.map { $0.id }
            var columns: [String:[String]] = [:]
            for (index, row) in rows.enumerated() {
                row.mergeWith(columns: &columns, index: index)
            }

            return Csv(name: name, rowHeaders: rowHeaders, columns: columns)
        }

        private static func convertObjectRow(id: String, json: JSON) throws -> ObjectRow {
            var objectRow = ObjectRow(id: id)
            try addTo(objectRow: &objectRow, prefix: nil, fieldJsons: try convertDictOrArrayToDict(json: json))
            return objectRow
        }

        private static func addTo(objectRow: inout ObjectRow, prefix: String?, fieldJsons: [String:JSON]) throws {
            for (fieldName, fieldJson) in fieldJsons {
                let fullFieldName = prefix.map { "\($0).\(fieldName)" } ?? fieldName
                switch fieldJson.type {
                case .number:
                    objectRow.fields[fullFieldName] = fieldJson.number!.description
                case .string:
                    objectRow.fields[fullFieldName] = fieldJson.string!
                case .bool:
                    // In the CSV format, booleans are in uppercase
                    // This is how LibreOffice represents them
                    objectRow.fields[fullFieldName] = fieldJson.bool!.description.uppercased()
                case .array:
                    let fieldJsonArray = fieldJson.array!
                    if fieldJsonArray.allSatisfy({ $0.type == .string && !$0.string!.contains(",") }) {
                        let fieldJsonArrayAsString = fieldJsonArray.map { $0.string! }.joined(separator: ", ")
                        objectRow.fields[fullFieldName] = fieldJsonArrayAsString
                    } else {
                        let fieldJsonArrayAsDictionary = [String: JSON](uniqueKeysWithValues: fieldJson.array!.enumerated().map {
                            ($0.offset.description, $0.element)
                        })
                        try addTo(objectRow: &objectRow, prefix: fullFieldName, fieldJsons: fieldJsonArrayAsDictionary)
                    }
                case .dictionary:
                    let fieldJsonDictionary = fieldJson.dictionary!
                    if fieldJsonDictionary.isEmpty {
                        objectRow.fields[fullFieldName] = "{}"
                    } else {
                        try addTo(objectRow: &objectRow, prefix: fullFieldName, fieldJsons: fieldJsonDictionary)
                    }
                case .null:
                    objectRow.fields[fullFieldName] = "NULL"
                case .unknown:
                    throw DecodeCsvError.encounteredLiteralUnknown
                }
            }
        }

        private static func convertDictOrArrayToDict(json: JSON) throws -> [String:JSON] {
            switch (json.type) {
            case .array:
                return [String:JSON](uniqueKeysWithValues: json.array!.enumerated().map { (index, objectJson) in
                    let id = index.description
                    return (id, objectJson)
                })
            case .dictionary:
                return json.dictionary!
            default:
                throw DecodeCsvError.wrongTypeMultipleOptions(expecteds: [.array, .dictionary], actual: json.type)
            }
        }
    }

    struct CsvsToJson: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "convert CSVs in a folder to a JSON")

        @Option(name: .shortAndLong, help: "column format")
        var columnFormat: ColumnFormat = .standard

        @Argument(help: "input directory of CSVs")
        var source: URL

        @Argument(help: "output JSON")
        var destination: URL

        mutating func run() {
            do {
                let json = try CsvsToJson.convert(source: source, columnFormat: columnFormat)
                try json.rawData(options: [.prettyPrinted]).write(to: destination, options: [.atomic])
            } catch {
                log(error: error)
            }
        }

        static func convert(source: URL, columnFormat: ColumnFormat) throws -> JSON {
            let sourceCsvs = try FileManager.default.contentsOfDirectory(at: source, includingPropertiesForKeys: []).filter {
                $0.pathExtension == "csv"
            }

            let jsonDict = Dictionary<String, JSON>(uniqueKeysWithValues: try sourceCsvs.map { sourceCsv in
                let csvName = sourceCsv.baseName.decapitalizedCamelCase
                let csvData = try CsvToJson.convert(source: sourceCsv, columnFormat: columnFormat)
                return (csvName, csvData)
            })
            return JSON(jsonDict)
        }
    }

    struct CsvsToJsonSplice: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "convert a folder of CSVs into a JSON, and insert as a top-level child of another JSON. Requires jq (https://stedolan.github.io/jq/)")

        @Option(name: .shortAndLong, help: "column format")
        var columnFormat: ColumnFormat = .standard

        @Argument(help: "input folder of CSVs")
        var source: URL

        @Argument(help: "JSON to insert splice")
        var parentDestination: URL

        @Argument(help: "key in JSON to replace with output")
        var spliceName: String

        mutating func run() {
            do {
                let spliceJson = try CsvsToJson.convert(source: source, columnFormat: columnFormat)

                try CsvToJsonSplice.splice(name: spliceName, json: spliceJson, into: parentDestination)
            } catch {
                log(error: error)
            }
        }
    }

    struct CsvToJsonSplice: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "convert a single CSV into a JSON, and insert as a top-level child of another JSON. Requires jq (https://stedolan.github.io/jq/)")

        private static let jqPath: String = "/usr/local/bin/jq"

        @Option(name: .shortAndLong, help: "column format")
        var columnFormat: ColumnFormat = .standard

        @Argument(help: "input CSV")
        var source: URL

        @Argument(help: "JSON to insert splice")
        var parentDestination: URL

        @Argument(help: "key in JSON to replace with output")
        var spliceName: String

        mutating func run() {
            do {
                let spliceJson = try CsvToJson.convert(source: source, columnFormat: columnFormat)
                try CsvToJsonSplice.splice(name: spliceName, json: spliceJson, into: parentDestination)
            } catch {
                log(error: error)
            }
        }

        static func splice(name spliceName: String, json spliceJson: JSON, into parentDestination: URL) throws {
            let parentInputHandle = try FileHandle(forReadingFrom: parentDestination)
            let outputPipe = Pipe()

            let spliceCommand = Process()
            if #available(macOS 10.13, *) {
                spliceCommand.executableURL = URL(fileURLWithPath: jqPath)
            } else {
                spliceCommand.launchPath = jqPath
            }
            spliceCommand.arguments = [".\(spliceName) = \(spliceJson)"]
            spliceCommand.standardInput = parentInputHandle
            spliceCommand.standardOutput = outputPipe

            if #available(macOS 10.13, *) {
                try spliceCommand.run()
            } else {
                spliceCommand.launch()
            }

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            spliceCommand.waitUntilExit()

            if spliceCommand.terminationStatus != 0 {
                print("splicing with jq failed: error code \(spliceCommand.terminationStatus), reason \(spliceCommand.terminationReason)")
            } else {
                try outputData.write(to: parentDestination, options: [.atomic])
            }
        }
    }

    struct CsvToJson: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "convert a single CSV to a JSON")

        @Option(name: .shortAndLong, help: "column format")
        var columnFormat: ColumnFormat = .standard

        @Argument(help: "input CSV")
        var source: URL

        @Argument(help: "output JSON")
        var destination: URL

        mutating func run() {
            do {
                let csv = Csv(try! String(contentsOf: source))
                let json = try! CsvToJson.convert(csv: csv, columnFormat: columnFormat)
                try json.rawData(options: [.prettyPrinted]).write(to: destination, options: [.atomic])
            } catch {
                log(error: error)
            }
        }

        static func convert(source: URL, columnFormat: ColumnFormat) throws -> JSON {
            let csv = Csv(try! String(contentsOf: source))
            return try convert(csv: csv, columnFormat: columnFormat)
        }

        private static func convert(csv: Csv, columnFormat: ColumnFormat) throws -> JSON {
            switch (columnFormat) {
            case .standard:
                var jsonDict: [String:JSON] = [:]
                for (columnIndex, header) in csv.headers.enumerated() {
                    if (Csv.shouldProcessEntry(header: header)) {
                        let columnFields = csv.fieldsAt(index: columnIndex)
                        let objectRow = ObjectRow(id: header, fields: columnFields)

                        jsonDict[header] = try convert(objectRow: objectRow)
                    }
                }

                return try convertToDictOrArray(jsonDict: jsonDict)
            case .array:
                var jsonArray: [[[JSON]]] = [[[]]]
                for (columnIndex, header) in csv.headers.enumerated() {
                    if (Csv.shouldProcessEntry(header: header)) {
                        let headerComponents = header.split(separator: "-")
                        if headerComponents.count != 3 || headerComponents.contains(where: {
                            Int($0) == nil
                        }) {
                            throw DecodeJsonError.badColumnHeader(header)
                        }

                        let columnFields = csv.fieldsAt(index: columnIndex)
                        let objectRow = ObjectRow(id: header, fields: columnFields)

                        let index2 = Int(headerComponents[0])!
                        let index1 = Int(headerComponents[1])!
                        let index0 = Int(headerComponents[2])!

                        jsonArray.padTo(minCount: index0 + 1, filler: [])
                        jsonArray[index0].padTo(minCount: index1 + 1, filler: [])
                        jsonArray[index0][index1].padTo(minCount: index2 + 1, filler: JSON.null)

                        jsonArray[index0][index1][index2] = try convert(objectRow: objectRow)
                    }
                }

                return JSON(jsonArray)
            }
        }

        private static func convert(objectRow: ObjectRow) throws -> JSON {
            try convert(objectRowFields: objectRow.fields)
        }

        private static func convert(objectRowFields: [String:String]) throws -> JSON {
            var jsonDict: [String:JSON] = [:]

            let groupedFields = Dictionary<String, [Dictionary<String, String>.Element]>(grouping: objectRowFields) { (fieldPair: Dictionary<String, String>.Element) -> String in
                let fullFieldName = fieldPair.key as String
                if fullFieldName.contains(".") {
                    return String(fullFieldName.split(separator: ".").first!)
                } else {
                    return ""
                }
            }.mapValues {
                Dictionary($0) { lhs, rhs in
                    log(warning: "Duplicate fields, their values are: \(lhs) and \(rhs)")
                    return "\(lhs), \(rhs)"
                }
            }

            for (fieldPrefix, subFields) in groupedFields {
                let areFieldsTopLevel = fieldPrefix.isEmpty
                if areFieldsTopLevel {
                    for (fieldName, field) in subFields {
                        if !field.isEmpty {
                            let fieldJson = try convert(datum: field)
                            jsonDict[fieldName] = fieldJson
                        }
                    }
                } else {
                    if subFields.values.contains(where: { !$0.isEmpty }) {
                        let childFields = subFields.mapKeys { fieldName in
                            fieldName.split(separator: ".").dropFirst().joined(separator: ".")
                        }
                        let childJson = try convert(objectRowFields: childFields)
                        jsonDict[fieldPrefix] = childJson
                    }
                }
            }

            return try convertToDictOrArray(jsonDict: jsonDict)
        }

        private static func convert(datum: String) throws -> JSON {
            if datum == "NULL" {
                return JSON.null
            } else if datum == "{}" {
                return JSON([:])
            } else if datum == "TRUE" {
                return JSON(true)
            } else if datum == "FALSE" {
                return JSON(false)
            } else if Int(datum) != nil && !datum.starts(with: "0x") {
                return JSON(Int(datum)!)
            } else if Double(datum) != nil && !datum.starts(with: "0x") {
                // Conversion to float causes a lot of floating-point errors for some reason,
                // conversion to double causes none as of writing this
                return JSON(Double(datum)!)
            } else if datum.hasPrefix("\"") && datum.hasSuffix("\"") {
                return JSON(String(datum.dropFirst().dropLast(1)).unescaped)
            } else if datum.hasPrefix("[") && datum.hasSuffix("]") {
                return JSON(datum.dropFirst().dropLast(1).split(separator: ",", omittingEmptySubsequences: false).map {
                    $0.trimmingCharacters(in: .whitespaces)
                })
            } else if datum.contains(", ") && !datum.replacingOccurrences(of: ", ", with: "").contains(" ") {
                return JSON(datum.split(separator: ",", omittingEmptySubsequences: false).map {
                    $0.trimmingCharacters(in: .whitespaces)
                })
            } else {
                return JSON(datum)
            }
        }

        /// Will convert to an array if the keys are literal integers
        private static func convertToDictOrArray(jsonDict: [String:JSON]) throws -> JSON {
            if jsonDict.keys.allSatisfy({ Int($0) != nil }) {
                let jsonDictWithIntKeys = jsonDict.mapKeys { Int($0)! }

                let jsonArrayCount = jsonDictWithIntKeys.count
                var jsonArray = [JSON](repeating: JSON.null, count: jsonArrayCount)
                for index in 0..<jsonArrayCount {
                    if !jsonDictWithIntKeys.keys.contains(index) {
                        print("Missing sub-array index: \(index)", stderr)
                        throw DecodeJsonError.missingSubArrayIndex(index)
                    }
                    jsonArray[index] = jsonDictWithIntKeys[index]!
                }

                return JSON(jsonArray)
            } else {
                return JSON(jsonDict)
            }
        }
    }
}

JsonCsv.main()
