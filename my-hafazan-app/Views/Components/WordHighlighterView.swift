import SwiftUI

struct WordHighlighterView: View {
    let words: [CachedWord]
    let currentWordIndex: Int

    var body: some View {
        AyahTextView(
            text: words.map { $0.textUthmani.cleanArabic }.joined(separator: " "),
            fontSize: 28,
            highlightedWordIndex: currentWordIndex,
            words: words
        )
    }
}
