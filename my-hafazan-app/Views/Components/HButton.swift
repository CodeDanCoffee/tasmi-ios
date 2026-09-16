import SwiftUI

struct HButton: View {
    let title: String
    var icon: String? = nil
    var style: HButtonStyle = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    enum HButtonStyle {
        case primary, secondary, outline
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: HSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                } else {
                    if let icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .font(HFont.bodyMedium)
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: HSpacing.cornerRadius))
            .overlay {
                if style == .outline {
                    RoundedRectangle(cornerRadius: HSpacing.cornerRadius)
                        .stroke(Color.hOliveGreen, lineWidth: 1.5)
                }
            }
        }
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }

    private var textColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .hOliveGreen
        case .outline: return .hOliveGreen
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .hOliveGreen
        case .secondary: return .hOliveLight
        case .outline: return .clear
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HButton(title: "Primary Button", icon: "arrow.right") {}
        HButton(title: "Secondary", style: .secondary) {}
        HButton(title: "Outline", style: .outline) {}
        HButton(title: "Loading", isLoading: true) {}
    }
    .padding()
    .background(Color.hCreamBg)
}
