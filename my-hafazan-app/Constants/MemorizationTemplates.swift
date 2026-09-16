import Foundation

struct MemorizationTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let stages: [Int]
    let isRecommended: Bool

    static let all: [MemorizationTemplate] = [
        MemorizationTemplate(
            id: "standard",
            name: "Standard",
            description: "The full journey. Recommended for most new ranges.",
            icon: "checkmark.shield",
            stages: [1, 2, 3, 4, 5, 6, 7, 8],
            isRecommended: true
        ),
        MemorizationTemplate(
            id: "gentle",
            name: "Gentle",
            description: "More repetition in the early stages. For beginners or long ayahs.",
            icon: "headphones",
            stages: [1, 1, 2, 2, 3, 3, 4, 5, 7, 8],
            isRecommended: false
        ),
        MemorizationTemplate(
            id: "revision",
            name: "Revision",
            description: "Straight to recall. For ayahs you've memorised before.",
            icon: "bolt",
            stages: [1, 4, 7, 8],
            isRecommended: false
        )
    ]
}
