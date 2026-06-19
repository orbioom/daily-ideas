import Foundation
import SwiftData
import SwiftUI

@Observable
final class HikeViewModel {
    var searchText: String = ""
    var selectedDifficulty: TrailDifficulty? = nil
    var showFavoritesOnly: Bool = false
    var sortOrder: TrailSortOrder = .name

    enum TrailSortOrder: String, CaseIterable {
        case name = "Name"
        case recentlyHiked = "Recently Hiked"
        case mostVisited = "Most Visited"
        case difficulty = "Difficulty"
    }

    func filteredTrails(_ trails: [Trail]) -> [Trail] {
        var result = trails
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let diff = selectedDifficulty {
            result = result.filter { $0.difficulty == diff }
        }
        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }
        switch sortOrder {
        case .name:
            result.sort { $0.name < $1.name }
        case .recentlyHiked:
            result.sort {
                ($0.lastHikedDate ?? .distantPast) > ($1.lastHikedDate ?? .distantPast)
            }
        case .mostVisited:
            result.sort { $0.sessionCount > $1.sessionCount }
        case .difficulty:
            let order: [TrailDifficulty] = [.easy, .moderate, .hard, .expert]
            result.sort {
                (order.firstIndex(of: $0.difficulty) ?? 0) <
                (order.firstIndex(of: $1.difficulty) ?? 0)
            }
        }
        return result
    }
}

@Observable
final class HikeEngine {
    func totalDistanceKm(_ sessions: [HikeSession]) -> Double {
        sessions.reduce(0) { $0 + $1.distanceKm }
    }

    func totalElevationM(_ sessions: [HikeSession]) -> Double {
        sessions.reduce(0) { $0 + $1.elevationGainM }
    }

    func totalHours(_ sessions: [HikeSession]) -> Double {
        Double(sessions.reduce(0) { $0 + $1.durationMinutes }) / 60.0
    }

    func averageRating(_ sessions: [HikeSession]) -> Double {
        let rated = sessions.filter { $0.rating > 0 }
        guard !rated.isEmpty else { return 0 }
        return Double(rated.reduce(0) { $0 + $1.rating }) / Double(rated.count)
    }

    func sessionsThisMonth(_ sessions: [HikeSession]) -> [HikeSession] {
        let cal = Calendar.current
        let now = Date()
        return sessions.filter { cal.isDate($0.date, equalTo: now, toGranularity: .month) }
    }

    func sessionsThisYear(_ sessions: [HikeSession]) -> [HikeSession] {
        let cal = Calendar.current
        let now = Date()
        return sessions.filter { cal.isDate($0.date, equalTo: now, toGranularity: .year) }
    }

    func weeklyDistances(_ sessions: [HikeSession]) -> [(week: String, km: Double)] {
        let cal = Calendar.current
        let now = Date()
        var result: [(String, Double)] = []
        for i in (0..<8).reversed() {
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -i, to: now) else { continue }
            let weekSessions = sessions.filter {
                cal.isDate($0.date, equalTo: weekStart, toGranularity: .weekOfYear)
            }
            let label = i == 0 ? "This Wk" : "W-\(i)"
            result.append((label, weekSessions.reduce(0) { $0 + $1.distanceKm }))
        }
        return result
    }

    func monthlyElevations(_ sessions: [HikeSession]) -> [(month: String, m: Double)] {
        let cal = Calendar.current
        let now = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        var result: [(String, Double)] = []
        for i in (0..<6).reversed() {
            guard let monthDate = cal.date(byAdding: .month, value: -i, to: now) else { continue }
            let monthSessions = sessions.filter {
                cal.isDate($0.date, equalTo: monthDate, toGranularity: .month)
            }
            result.append((fmt.string(from: monthDate), monthSessions.reduce(0) { $0 + $1.elevationGainM }))
        }
        return result
    }
}
