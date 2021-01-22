//
// Created by Jakob Hain on 11/28/20.
// Copyright (c) 2020 Jakobeha. All rights reserved.
//

import Foundation

protocol HasDefault {
    static var defaultValue: Self { get }
}

extension String: HasDefault {
    static var defaultValue: Self {
        ""
    }
}
