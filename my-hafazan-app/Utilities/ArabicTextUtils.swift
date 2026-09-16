import Foundation

enum ArabicTextUtils {
    // Unicode ranges for Arabic diacritics (tashkeel)
    private static let tashkeelRange: [ClosedRange<UInt32>] = [
        0x064B...0x065F,  // Fathatan through Waslah
        0x0670...0x0670,  // Superscript Alef
        0x06D6...0x06DC,  // Small high ligature sad through small high seen
        0x06DF...0x06E4,  // Small high rounded zero through small high madda
        0x06E7...0x06E8,  // Small high yeh through small high noon
        0x06EA...0x06ED   // Empty centre low stop through small low meem
    ]

    /// Remove tashkeel (diacritics) from Arabic text
    static func stripTashkeel(_ text: String) -> String {
        text.unicodeScalars.filter { scalar in
            !tashkeelRange.contains(where: { $0.contains(scalar.value) })
        }
        .map { String($0) }
        .joined()
    }

    /// Get the first letter of each word (for hints)
    static func firstLetterHints(_ text: String) -> [String] {
        let words = text.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        return words.map { word in
            let stripped = stripTashkeel(word)
            guard let firstChar = stripped.first else { return "" }
            return String(firstChar) + "..."
        }
    }

    /// Get first letter with original tashkeel preserved
    static func firstLetterWithTashkeel(_ word: String) -> String {
        guard !word.isEmpty else { return "" }
        var result = ""
        var foundBase = false

        for scalar in word.unicodeScalars {
            if !foundBase {
                result.append(String(scalar))
                if !tashkeelRange.contains(where: { $0.contains(scalar.value) }) {
                    foundBase = true
                }
            } else if tashkeelRange.contains(where: { $0.contains(scalar.value) }) {
                result.append(String(scalar))
            } else {
                break
            }
        }

        return result
    }

    /// Compare two Arabic texts ignoring tashkeel
    static func compare(_ text1: String, _ text2: String) -> Double {
        let stripped1 = stripTashkeel(text1).replacingOccurrences(of: " ", with: "")
        let stripped2 = stripTashkeel(text2).replacingOccurrences(of: " ", with: "")

        guard !stripped1.isEmpty else { return 0 }

        let chars1 = Array(stripped1)
        let chars2 = Array(stripped2)
        var matchCount = 0

        for (i, char) in chars2.enumerated() {
            if i < chars1.count && chars1[i] == char {
                matchCount += 1
            }
        }

        return Double(matchCount) / Double(chars1.count)
    }

    /// Diff two texts and return array of (character, isCorrect)
    static func diff(_ attempt: String, _ original: String) -> [(String, Bool)] {
        let strippedAttempt = stripTashkeel(attempt)
        let strippedOriginal = stripTashkeel(original)

        let attemptChars = Array(strippedAttempt)
        let originalChars = Array(strippedOriginal)
        var result: [(String, Bool)] = []

        for (i, char) in attemptChars.enumerated() {
            let isCorrect = i < originalChars.count && originalChars[i] == char
            result.append((String(char), isCorrect))
        }

        return result
    }
}
