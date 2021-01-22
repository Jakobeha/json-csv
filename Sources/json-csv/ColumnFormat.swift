//
// Created by Jakob Hain on 12/4/20.
// Copyright (c) 2020 Jakobeha. All rights reserved.
//

import ArgumentParser
import Foundation

enum ColumnFormat: String, CaseIterable, ExpressibleByArgument {
    case standard
    case array

    public init?(argument: String) {
        self.init(rawValue: argument)
    }

    public var defaultValueDescription: String {
        rawValue
    }

    public static var defaultCompletionKind: CompletionKind {
        CompletionKind.list(allCases.map { $0.rawValue })
    }
}