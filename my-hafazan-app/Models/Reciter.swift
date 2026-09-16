import Foundation

struct RecitersResponse: Codable {
    let recitations: [Reciter]
}

struct Reciter: Codable, Identifiable, Hashable {
    let id: Int
    let reciterName: String
    let style: String?
    let translatedName: ReciterTranslatedName?

    struct ReciterTranslatedName: Codable, Hashable {
        let name: String
        let languageName: String
    }
}

struct AudioFilesResponse: Codable {
    let audioFiles: [AudioFile]
}

struct AudioFile: Codable, Identifiable, Hashable {
    let id: Int
    let chapterId: Int
    let fileSize: Double?
    let format: String?
    let audioUrl: String?
    let verseTimings: [VerseTiming]?
}

struct VerseTiming: Codable, Hashable {
    let verseKey: String
    let timestampFrom: Int
    let timestampTo: Int
    let segments: [[Int]]?
}

struct ChapterRecitationResponse: Codable {
    let audioFile: ChapterAudioFile
}

struct ChapterAudioFile: Codable {
    let id: Int
    let chapterId: Int
    let fileSize: Double?
    let format: String?
    let audioUrl: String?
    let timestamps: [VerseTiming]?
}
