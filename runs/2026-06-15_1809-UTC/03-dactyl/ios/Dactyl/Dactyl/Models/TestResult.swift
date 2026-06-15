import Foundation
import SwiftData

/// How a typing session was produced — used for filtering and labelling history.
enum SessionMode: String, Codable, CaseIterable {
    case lesson
    case test
    case drill

    var label: String {
        switch self {
        case .lesson: return "Lesson"
        case .test: return "Test"
        case .drill: return "Drill"
        }
    }

    var systemImage: String {
        switch self {
        case .lesson: return "graduationcap.fill"
        case .test: return "stopwatch.fill"
        case .drill: return "pencil.and.scribble"
        }
    }
}

/// A completed typing session. Per-key error counts are stored as JSON `Data` and decoded safely.
@Model
final class TestResult {
    @Attribute(.unique) var id: UUID
    var date: Date
    var modeRaw: String
    var referenceTitle: String
    var wpm: Double
    var accuracy: Double          // 0...1
    var durationSeconds: Double
    var charCount: Int
    var errorCount: Int
    /// JSON-encoded `[String: Int]` of per-key error counts (lowercased key name).
    var keyErrorsData: Data

    init(id: UUID = UUID(),
         date: Date = Date(),
         mode: SessionMode,
         referenceTitle: String,
         wpm: Double,
         accuracy: Double,
         durationSeconds: Double,
         charCount: Int,
         errorCount: Int,
         keyErrors: [String: Int]) {
        self.id = id
        self.date = date
        self.modeRaw = mode.rawValue
        self.referenceTitle = referenceTitle
        self.wpm = wpm
        self.accuracy = accuracy
        self.durationSeconds = durationSeconds
        self.charCount = charCount
        self.errorCount = errorCount
        self.keyErrorsData = TestResult.encode(keyErrors)
    }

    var mode: SessionMode {
        SessionMode(rawValue: modeRaw) ?? .test
    }

    /// Decoded per-key error counts; returns empty on any decode failure (never throws/crashes).
    var keyErrors: [String: Int] {
        (try? JSONDecoder().decode([String: Int].self, from: keyErrorsData)) ?? [:]
    }

    static func encode(_ dict: [String: Int]) -> Data {
        (try? JSONEncoder().encode(dict)) ?? Data("{}".utf8)
    }
}
