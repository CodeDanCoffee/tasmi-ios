import Foundation

enum StageType: Int, CaseIterable, Codable {
    case listenWithText = 1
    case listenOnly = 2
    case readWithHints = 3
    case readFromMemory = 4
    case write = 5
    case recite = 6
    case prayerCount = 7
    case shareReflection = 8

    var title: String {
        switch self {
        case .listenWithText: return "Meet the Ayahs"
        case .listenOnly: return "First Recall"
        case .readWithHints: return "Recite the Sequence"
        case .readFromMemory: return "Bridge the Gaps"
        case .write: return "Continue from Here"
        case .recite: return "Chain Challenge"
        case .prayerCount: return "Recite in Prayer"
        case .shareReflection: return "Share a Reflection"
        }
    }

    var subtitle: String {
        switch self {
        case .listenWithText: return "Listen, match translations, read aloud."
        case .listenOnly: return "Fill the gaps. Easy, then harder."
        case .readWithHints: return "Produce the ayahs in order, aloud."
        case .readFromMemory: return "Ayah-to-ayah transitions."
        case .write: return "Pick up from a natural pause."
        case .recite: return "Recite the full range, unaided."
        case .prayerCount: return "Bring the ayahs into your salah."
        case .shareReflection: return "Share what these ayahs left with you."
        }
    }

    var icon: String {
        switch self {
        case .listenWithText: return "headphones"
        case .listenOnly: return "ear"
        case .readWithHints: return "text.magnifyingglass"
        case .readFromMemory: return "brain.head.profile"
        case .write: return "pencil.line"
        case .recite: return "mic"
        case .prayerCount: return "moon.stars"
        case .shareReflection: return "text.bubble"
        }
    }

    var isGate: Bool {
        self == .recite
    }

    var showsText: Bool {
        switch self {
        case .listenWithText: return true
        case .readWithHints: return true
        default: return false
        }
    }

    var hasAudio: Bool {
        switch self {
        case .listenWithText, .listenOnly: return true
        default: return false
        }
    }
}
