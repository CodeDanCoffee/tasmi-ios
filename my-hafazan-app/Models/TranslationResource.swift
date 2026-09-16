import Foundation

struct TranslationsResourceResponse: Codable {
    let translations: [TranslationResource]
}

struct TranslationResource: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let authorName: String?
    let slug: String?
    let languageName: String
    let translatedName: TranslatedName?

    struct TranslatedName: Codable, Hashable {
        let name: String
        let languageName: String
    }

    /// ISO-ish code used by the `language` query param on the verses endpoint
    /// for word-by-word translations. Maps from the API's full `language_name`
    /// (e.g. "english") to the short code the verses endpoint expects.
    /// Falls back to "en" so a missing entry never breaks the request.
    var languageCode: String {
        let key = languageName.lowercased()
        return Self.languageCodes[key] ?? "en"
    }

    private static let languageCodes: [String: String] = [
        "albanian": "sq",
        "amharic": "am",
        "arabic": "ar",
        "azerbaijani": "az",
        "bengali": "bn",
        "bosnian": "bs",
        "bulgarian": "bg",
        "chechen": "ce",
        "chinese": "zh",
        "czech": "cs",
        "divehi": "dv",
        "dutch": "nl",
        "english": "en",
        "french": "fr",
        "georgian": "ka",
        "german": "de",
        "hausa": "ha",
        "hindi": "hi",
        "indonesian": "id",
        "italian": "it",
        "japanese": "ja",
        "kannada": "kn",
        "kazakh": "kk",
        "korean": "ko",
        "kurdish": "ku",
        "malay": "ms",
        "malayalam": "ml",
        "norwegian": "no",
        "pashto": "ps",
        "persian": "fa",
        "polish": "pl",
        "portuguese": "pt",
        "romanian": "ro",
        "russian": "ru",
        "sindhi": "sd",
        "somali": "so",
        "spanish": "es",
        "swahili": "sw",
        "swedish": "sv",
        "tagalog": "tl",
        "tajik": "tg",
        "tamil": "ta",
        "thai": "th",
        "turkish": "tr",
        "ukrainian": "uk",
        "urdu": "ur",
        "uyghur": "ug",
        "uzbek": "uz",
        "vietnamese": "vi"
    ]
}
