import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    var color: Color = .hOliveGreen
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color.opacity(0.2))
                    .frame(height: height)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geo.size.width * min(max(progress, 0), 1), height: height)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBarView(progress: 0.3)
        ProgressBarView(progress: 0.7, color: .hModerateYellow)
        ProgressBarView(progress: 1.0, color: .hStrongGreen, height: 10)
    }
    .padding()
}
