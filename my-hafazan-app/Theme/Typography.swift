import SwiftUI
import UIKit

enum HFont {
    // General Sans - UI text (variable font)
    static func generalSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let uiWeight: UIFont.Weight
        switch weight {
        case .bold, .heavy, .black:
            uiWeight = .bold
        case .semibold:
            uiWeight = .semibold
        case .medium:
            uiWeight = .medium
        case .light:
            uiWeight = .light
        default:
            uiWeight = .regular
        }

        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: "General Sans Variable",
            .traits: [UIFontDescriptor.TraitKey.weight: uiWeight]
        ])
        return Font(UIFont(descriptor: descriptor, size: size))
    }

    // Playfair Display - Headings (variable font)
    static func sourceSerif(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        let uiWeight: UIFont.Weight
        switch weight {
        case .bold, .heavy, .black:
            uiWeight = .bold
        case .semibold:
            uiWeight = .semibold
        case .medium:
            uiWeight = .medium
        default:
            uiWeight = .regular
        }

        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: "Playfair Display",
            .traits: [UIFontDescriptor.TraitKey.weight: uiWeight]
        ])
        return Font(UIFont(descriptor: descriptor, size: size))
    }

    // KFGQPC Uthmanic Script HAFS - Arabic Quran text
    static func amiriQuran(_ size: CGFloat) -> Font {
        .custom("KFGQPCUthmanicScriptHAFS", size: size)
    }

    // Amiri - Arabic UI
    static func amiri(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Amiri-Regular", size: size)
    }

    // Predefined styles
    static let title = sourceSerif(28, weight: .bold)
    static let heading = sourceSerif(22, weight: .semibold)
    static let subheading = generalSans(17, weight: .semibold)
    static let body = generalSans(15)
    static let bodyMedium = generalSans(15, weight: .medium)
    static let caption = generalSans(13)
    static let captionMedium = generalSans(13, weight: .medium)
    static let arabicLarge = amiriQuran(32)
    static let arabicMedium = amiriQuran(28)
    static let arabicSmall = amiriQuran(22)
}

struct ArabicTextStyle: ViewModifier {
    var size: CGFloat = 32

    func body(content: Content) -> some View {
        content
            .font(HFont.amiriQuran(size))
            .multilineTextAlignment(.trailing)
            .lineSpacing(16)
    }
}

extension View {
    func arabicStyle(size: CGFloat = 28) -> some View {
        modifier(ArabicTextStyle(size: size))
    }
}
