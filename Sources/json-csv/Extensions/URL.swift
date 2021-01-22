//
// Created by Jakob Hain on 11/24/20.
// Copyright (c) 2020 Jakobeha. All rights reserved.
//

import Foundation
import ArgumentParser

extension URL {
    var baseName: String {
        deletingPathExtension().lastPathComponent
    }
}

extension URL: ExpressibleByArgument {
    static let workingDirectory: URL = URL(fileURLWithPath: CommandLine.arguments[0])

    public init?(argument: String) {
        self.init(string: argument, relativeTo: URL.workingDirectory)
    }

    public var defaultValueDescription: String {
        relativePath
    }

    public static var defaultCompletionKind: CompletionKind {
        CompletionKind.file()
    }
}