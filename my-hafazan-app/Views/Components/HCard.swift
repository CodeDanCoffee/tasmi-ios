import SwiftUI

struct HCard<Content: View>: View {
    var padding: CGFloat = HSpacing.cardPadding
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(Color.hCardBg)
            .clipShape(RoundedRectangle(cornerRadius: HSpacing.cornerRadius))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

#Preview {
    HCard {
        VStack(alignment: .leading) {
            Text("Card Title")
                .font(HFont.subheading)
            Text("Card content goes here")
                .font(HFont.body)
                .foregroundStyle(Color.hSubtext)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding()
    .background(Color.hCreamBg)
}
