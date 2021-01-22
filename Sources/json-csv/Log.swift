//
// Created by Jakob Hain on 12/4/20.
// Copyright (c) 2020 Jakobeha. All rights reserved.
//

import Foundation

func log(warning: String) {
    print("Warning: \(warning)")
}

func log(error: Error) {
    print("Failed: \(error.localizedDescription)", stderr)
}