import SwiftUI

struct AyahTextView: View {
    let text: String
    var fontSize: CGFloat = 32
    var textColor: Color = .hDarkText
    var highlightedWordIndex: Int = -1
    var words: [CachedWord]? = nil
    var showTranslation: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let words = words, !words.isEmpty {
                // Word-by-word rendering for highlighting
                WrappingHStack(words: words, fontSize: fontSize, highlightedIndex: highlightedWordIndex, defaultColor: textColor)
            } else {
                Text(text)
                    .arabicStyle(size: fontSize)
                    .foregroundStyle(textColor)
            }

            if showTranslation {
                let translation = translationText
                if !translation.isEmpty {
                    Text(translation)
                        .font(HFont.generalSans(14))
                        .foregroundStyle(Color(red: 122/255, green: 114/255, blue: 106/255))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(3)
                }
            }
        }
    }

    private var translationText: String {
        guard let words = words else { return "" }
        return words
            .filter { $0.charTypeName == "word" }
            .compactMap { $0.translation }
            .joined(separator: " ")
    }
}

struct WrappingHStack: View {
    let words: [CachedWord]
    let fontSize: CGFloat
    let highlightedIndex: Int
    var defaultColor: Color = .hDarkText

    var body: some View {
        Text(attributedText)
            .font(HFont.amiriQuran(fontSize))
            .multilineTextAlignment(.trailing)
            .lineSpacing(16)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .animation(.easeInOut(duration: 0.15), value: highlightedIndex)
    }

    private var attributedText: AttributedString {
        var result = AttributedString()
        let wordItems = words.filter { $0.charTypeName == "word" }

        for (index, word) in wordItems.enumerated() {
            if index > 0 {
                result += AttributedString(" ")
            }
            var attr = AttributedString(word.textUthmani.cleanArabic)
            if index == highlightedIndex {
                attr.foregroundColor = Color.hOliveGreen
                attr.backgroundColor = Color.hOliveGreen.opacity(0.15)
            } else {
                attr.foregroundColor = defaultColor
            }
            result += attr
        }
        return result
    }
}

#Preview {
    VStack(spacing: 20) {
        AyahTextView(text: "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
        AyahTextView(text: "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ", fontSize: 22)
    }
    .padding()
}
