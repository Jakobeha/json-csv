//
// Created by Jakob Hain on 5/10/20.
// Copyright (c) 2020 Jakobeha. All rights reserved.
//

import Foundation

extension String {
    // Copied from https://stackoverflow.com/questions/24318171/using-swift-to-unescape-unicode-characters-ie-u1234?noredirect=1&lq=1
    var unescaped: String {
        let mutableString = NSMutableString(string: self)
        CFStringTransform(mutableString, nil, "Any-Hex/Java" as NSString, true)

        return mutableString as String
    }

    /// Capitalizes the first letter but leaves the rest of the string unchanged
    var capitalizedCamelCase: String {
        var result = self
        let firstCharacterRange = ..<index(after: startIndex)
        result.modify(range: firstCharacterRange) { firstCharacter in
            firstCharacter.uppercased()
        }
        return result
    }

    /// Lowercases the first letter but leaves the rest of the string unchanged
    var decapitalizedCamelCase: String {
        var result = self
        let firstCharacterRange = ..<index(after: startIndex)
        result.modify(range: firstCharacterRange) { firstCharacter in
            firstCharacter.lowercased()
        }
        return result
    }

    /// Example: "fooBarBaz" => "foo bar baz"
    var camelCaseToSubSentenceCase: String {
        let words = wordsInCamelCase
        return words.joined(separator: " ")
    }

    /// Example: "fooBarBaz" => "Foo bar baz"
    var camelCaseToSentenceCase: String {
        var words = wordsInCamelCase
        words[0] = words[0].capitalized
        return words.joined(separator: " ")
    }

    /// Example: "fooBarBaz" => ["foo", "bar", "baz"]
    var wordsInCamelCase: [String] {
        var words: [String] = []

        var remaining = self
        while let nextSplitIndex = remaining.firstIndex(where: { character in character.isUppercase }) {
            // Make the first character lowercase, since the resulting words are lowercase
            if !remaining.isEmpty {
                let firstCharacterRange = ..<remaining.index(after: remaining.startIndex)
                remaining.modify(range: firstCharacterRange) { firstCharacter in
                    firstCharacter.lowercased()
                }
            }

            // Get the next word and range
            let nextWordRange = ..<nextSplitIndex
            let nextWord = remaining[nextWordRange]

            // Add the next word
            words.append(String(nextWord))

            // Remove the range from remaining
            remaining.removeSubrange(nextWordRange)
        }
        words.append(remaining)

        return words
    }

    func leftPadding(toLength newLength: Int, withPad character: Character) -> String {
        String(repeatElement(character, count: newLength - self.count)) + self
    }

    func strip(prefix: String) -> Substring? {
        starts(with: prefix) ? self[index(startIndex, offsetBy: prefix.count)...] : nil
    }

    mutating func modify<R: RangeExpression, C: Collection>(range: R, with transformer: (Substring) throws -> C) rethrows where R.Bound == Index, C.Element == Element {
        replaceSubrange(range, with: try transformer(self[range]))
    }
}
