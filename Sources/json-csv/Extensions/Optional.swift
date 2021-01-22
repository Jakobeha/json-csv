//
// Created by Jakob Hain on 5/12/20.
// Copyright (c) 2020 Jakobeha. All rights reserved.
//

import Foundation

extension Optional {
    func orThrow(_ getError: () -> Error) throws -> Wrapped {
        if let wrapped = self {
            return wrapped
        } else {
            throw getError()
        }
    }
}
