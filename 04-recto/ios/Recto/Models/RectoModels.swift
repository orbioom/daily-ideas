import SwiftData
import Foundation

enum BulletType: String, Codable, CaseIterable {
    case task = "task"
    case event = "event"
    case note = "note"

    var displayName: String {
        switch self {
        case .task: return "Task"
        case .event: return "Event"
        case .note: return "Note"
        }
    }
}

enum TaskStatus: String, Codable {
    case open = "open"
    case complete = "complete"
    case migrated = "migrated"
    case irrelevant = "irrelevant"
}

@Model final class BulletEntry {
    var id: UUID
    var date: Date
    var bulletType: String      // BulletType.rawValue
    var status: String          // TaskStatus.rawValue (for tasks)
    var text: String
    var collectionId: UUID?     // nil = daily log
    var isStarred: Bool
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        date: Date = .now,
        bulletType: BulletType = .task,
        status: TaskStatus = .open,
        text: String,
        collectionId: UUID? = nil,
        isStarred: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.date = date
        self.bulletType = bulletType.rawValue
        self.status = status.rawValue
        self.text = text
        self.collectionId = collectionId
        self.isStarred = isStarred
        self.sortOrder = sortOrder
    }

    var bulletTypeEnum: BulletType { BulletType(rawValue: bulletType) ?? .task }
    var statusEnum: TaskStatus { TaskStatus(rawValue: status) ?? .open }

    var bulletSymbol: String {
        switch bulletTypeEnum {
        case .task:
            switch statusEnum {
            case .open: return "•"
            case .complete: return "×"
            case .migrated: return ">"
            case .irrelevant: return "⊘"
            }
        case .event: return "○"
        case .note: return "–"
        }
    }

    var bulletColor: String {
        switch bulletTypeEnum {
        case .task: return "task"
        case .event: return "event"
        case .note: return "note"
        }
    }
}

@Model final class Collection {
    var id: UUID
    var name: String
    var icon: String        // SF Symbol name
    var colorHex: String    // hex string
    var createdAt: Date
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder",
        colorHex: String = "#007AFF",
        createdAt: Date = .now,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}

@Model final class RectoSettings {
    var theme: String               // "light" | "dark" | "system"
    var fontStyle: String           // "serif" | "sans"
    var showDateHeader: Bool
    var hapticEnabled: Bool
    var defaultBulletType: String   // BulletType.rawValue
    var hasCompletedOnboarding: Bool
    var isPro: Bool

    init() {
        theme = "system"
        fontStyle = "sans"
        showDateHeader = true
        hapticEnabled = true
        defaultBulletType = BulletType.task.rawValue
        hasCompletedOnboarding = false
        isPro = false
    }
}

// MARK: - Color Helpers
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
