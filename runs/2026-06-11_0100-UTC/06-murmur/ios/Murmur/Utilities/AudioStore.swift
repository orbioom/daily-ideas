import Foundation
import AVFoundation

enum AudioStore {
    static var audioDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("MurmurAudio")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func newFilename() -> String { UUID().uuidString + ".m4a" }

    static func url(for filename: String) -> URL {
        audioDirectory.appendingPathComponent(filename)
    }

    static func delete(_ filename: String) {
        let u = url(for: filename)
        try? FileManager.default.removeItem(at: u)
    }

    static func exists(_ filename: String) -> Bool {
        FileManager.default.fileExists(atPath: url(for: filename).path)
    }

    static func recordingSettings() -> [String: Any] {
        [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
    }
}
