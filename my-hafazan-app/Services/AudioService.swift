import Foundation
import AVFoundation
import Combine

@Observable
class AudioService {
    var isPlaying = false
    var currentTime: Double = 0
    var duration: Double = 0
    var currentWordIndex: Int = -1
    var activeVerseKey: String = ""
    var completedVerses: Set<String> = []

    // Sequential playback
    var isSequentialMode = false
    var currentVerseIndex = 0
    var currentPass = 1
    var totalPasses = 2
    var isSequentialComplete = false
    var sequentialVerseLimit: Int? = nil

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endOfItemObserver: NSObjectProtocol?
    private var verseTimings: [VerseTiming] = []
    private var currentSegments: [[Int]] = []

    /// The absolute start/end timestamps (ms) for the currently playing verse
    private var rangeStartMs: Int = 0
    private var rangeEndMs: Int = 0

    var allVersesCompleted: Bool {
        if isSequentialMode { return isSequentialComplete }
        return !verseTimings.isEmpty && verseTimings.allSatisfy { completedVerses.contains($0.verseKey) }
    }

    func loadAudio(url: String, timings: [VerseTiming] = [], verseStart: Int, verseEnd: Int, chapterId: Int) {
        stop()

        let selectedKeys = (verseStart...verseEnd).map { "\(chapterId):\($0)" }
        self.verseTimings = timings.filter { selectedKeys.contains($0.verseKey) }
        self.completedVerses = []

        guard let audioURL = URL(string: url) else { return }
        let item = AVPlayerItem(url: audioURL)
        player = AVPlayer(playerItem: item)

        // Fallback for last-verse completion when its timestampTo sits at or past
        // the actual audio end — the periodic observer's rangeEnd check can miss it.
        endOfItemObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.handleItemDidEnd()
        }

        setupTimeObserver()
    }

    private func handleItemDidEnd() {
        guard isSequentialMode, !isSequentialComplete else { return }
        if !activeVerseKey.isEmpty {
            completedVerses.insert(activeVerseKey)
        }
        isPlaying = false
        currentTime = duration
        isSequentialComplete = true
    }

    func toggleVerse(_ verseKey: String) {
        if isPlaying && activeVerseKey == verseKey {
            pause()
        } else {
            playVerse(verseKey)
        }
    }

    func isVerseCompleted(_ verseKey: String) -> Bool {
        completedVerses.contains(verseKey)
    }

    func stop() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        timeObserver = nil
        if let endObs = endOfItemObserver {
            NotificationCenter.default.removeObserver(endObs)
        }
        endOfItemObserver = nil
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        currentWordIndex = -1
        activeVerseKey = ""
        rangeStartMs = 0
        rangeEndMs = 0
        isSequentialMode = false
        isSequentialComplete = false
        sequentialVerseLimit = nil
    }

    /// Pauses and resets playback state but keeps the player and verse timings alive.
    func resetForNextActivity() {
        player?.pause()
        isPlaying = false
        isSequentialMode = false
        isSequentialComplete = false
        sequentialVerseLimit = nil
        currentVerseIndex = 0
        currentPass = 1
        currentTime = 0
        currentWordIndex = -1
        activeVerseKey = ""
    }

    // MARK: - Private

    private func playVerse(_ verseKey: String) {
        guard let timing = verseTimings.first(where: { $0.verseKey == verseKey }) else { return }

        activeVerseKey = verseKey
        currentSegments = timing.segments ?? []
        currentWordIndex = -1
        rangeStartMs = timing.timestampFrom
        rangeEndMs = timing.timestampTo
        duration = Double(rangeEndMs - rangeStartMs) / 1000.0
        currentTime = 0

        let startTime = CMTime(value: Int64(rangeStartMs), timescale: 1000)
        player?.seek(to: startTime) { [weak self] _ in
            self?.play()
        }
    }

    func play() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func setVolume(_ volume: Float) {
        player?.volume = volume
    }

    func toggle() {
        if isPlaying { pause() } else { play() }
    }

    // MARK: - Sequential Playback

    func toggleSequential() {
        if isSequentialComplete {
            // Restart from beginning
            startSequential()
            return
        }

        if isPlaying {
            pause()
        } else if !isSequentialMode || activeVerseKey.isEmpty {
            startSequential()
        } else {
            play()
        }
    }

    func startSequential(passes: Int = 1) {
        isSequentialMode = true
        totalPasses = passes
        currentPass = 1
        currentVerseIndex = 0
        isSequentialComplete = false
        completedVerses.removeAll()

        guard !verseTimings.isEmpty else { return }
        playVerse(verseTimings[0].verseKey)
    }

    private func onVerseCompleted() {
        completedVerses.insert(activeVerseKey)
        currentWordIndex = -1

        if isSequentialMode {
            currentVerseIndex += 1
            if let limit = sequentialVerseLimit, currentVerseIndex >= limit {
                player?.pause()
                isPlaying = false
                currentTime = duration
                isSequentialComplete = true
                return
            }
            if currentVerseIndex < verseTimings.count {
                playVerse(verseTimings[currentVerseIndex].verseKey)
            } else if currentPass < totalPasses {
                currentPass += 1
                currentVerseIndex = 0
                completedVerses.removeAll()
                playVerse(verseTimings[0].verseKey)
            } else {
                player?.pause()
                isPlaying = false
                currentTime = duration
                isSequentialComplete = true
            }
        } else {
            player?.pause()
            isPlaying = false
            currentTime = duration
        }
    }

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.05, preferredTimescale: 1000)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self, self.isPlaying else { return }
            let absoluteMs = Int(time.seconds * 1000)

            self.currentTime = max(0, time.seconds - Double(self.rangeStartMs) / 1000.0)

            // Stop when we reach the end of this verse
            if absoluteMs >= self.rangeEndMs && self.rangeEndMs > 0 {
                self.onVerseCompleted()
                return
            }

            self.updateWordHighlight(at: time.seconds)
        }
    }

    private func updateWordHighlight(at time: Double) {
        let timeMs = Int(time * 1000)

        for (index, segment) in currentSegments.enumerated() {
            guard segment.count >= 3 else { continue }
            let start = segment[1]
            let end = segment[2]
            if timeMs >= start && timeMs < end {
                if currentWordIndex != index {
                    currentWordIndex = index
                }
                return
            }
        }
    }
}
