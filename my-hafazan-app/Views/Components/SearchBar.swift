import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."

    var body: some View {
        HStack(spacing: HSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.hSubtext)

            TextField(placeholder, text: $text)
                .font(HFont.body)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.hSubtext)
                }
            }
        }
        .padding(HSpacing.md)
        .background(Color.hDarkText.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: HSpacing.cornerRadiusSm))
    }
}

#Preview {
    SearchBar(text: .constant("Al-Fatihah"))
        .padding()
        .background(Color.hCreamBg)
}
