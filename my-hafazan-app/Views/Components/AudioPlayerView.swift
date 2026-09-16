import SwiftUI

struct AudioPlayerView: View {
    @Bindable var audioService: AudioService

    var body: some View {
        VStack(spacing: HSpacing.md) {
            // Progress bar
            ProgressBarView(progress: audioService.duration > 0 ? audioService.currentTime / audioService.duration : 0)
                .frame(height: 4)

            // Time labels + controls
            HStack {
                Text(formatTime(audioService.currentTime))
                    .font(HFont.caption)
                    .foregroundStyle(Color.hSubtext)

                Spacer()

                // Play/Pause button
                Button {
                    audioService.toggle()
                } label: {
                    Image(systemName: audioService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.hOliveGreen)
                }

                Spacer()

                Text(formatTime(audioService.duration))
                    .font(HFont.caption)
                    .foregroundStyle(Color.hSubtext)
            }
        }
        .padding(.horizontal, HSpacing.lg)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}
