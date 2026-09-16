import SwiftUI

struct StageIndicatorView: View {
    let currentStage: Int
    let totalStages: Int

    var body: some View {
        HStack(spacing: HSpacing.sm) {
            ForEach(1...totalStages, id: \.self) { stage in
                Circle()
                    .fill(stage < currentStage ? Color.hOliveGreen :
                          stage == currentStage ? Color.hOliveGreen :
                          Color.hBorder)
                    .frame(width: stage == currentStage ? 12 : 8,
                           height: stage == currentStage ? 12 : 8)
                    .overlay {
                        if stage < currentStage {
                            Image(systemName: "checkmark")
                                .font(.system(size: 5, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: currentStage)

                if stage < totalStages {
                    Rectangle()
                        .fill(stage < currentStage ? Color.hOliveGreen : Color.hBorder)
                        .frame(height: 2)
                        .animation(.easeInOut(duration: 0.3), value: currentStage)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StageIndicatorView(currentStage: 1, totalStages: 7)
        StageIndicatorView(currentStage: 4, totalStages: 7)
        StageIndicatorView(currentStage: 7, totalStages: 7)
    }
    .padding()
}
