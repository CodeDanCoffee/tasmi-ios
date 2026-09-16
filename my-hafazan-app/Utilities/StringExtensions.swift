import Foundation

extension String {
    func strippingHTML() -> String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    /// Strip Quranic annotation marks (U+06D6–U+06ED) that the KFGQPC font renders as black dots
    var cleanArabic: String {
        String(unicodeScalars.filter { $0.value < 0x06D6 || $0.value > 0x06ED })
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
