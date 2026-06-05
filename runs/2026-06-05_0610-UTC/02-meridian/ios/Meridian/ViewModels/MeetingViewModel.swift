import Foundation
import SwiftUI

@MainActor
final class MeetingViewModel: ObservableObject {
    @Published var participants: [Participant] { didSet { save() } }
    @Published var workStart: Int { didSet { save() } }   // local hour, inclusive
    @Published var workEnd: Int { didSet { save() } }       // local hour, exclusive
    @Published var selectedUTCHour: Int?

    private let key = "meridian.state.v1"
    let referenceDate = Date()

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let s = try? JSONDecoder().decode(SavedState.self, from: data) {
            participants = s.participants
            workStart = s.workStart
            workEnd = s.workEnd
        } else {
            participants = [
                Participant(name: "You", city: "San Francisco", tzIdentifier: "America/Los_Angeles"),
                Participant(name: "Design", city: "London", tzIdentifier: "Europe/London"),
                Participant(name: "Eng", city: "Mumbai", tzIdentifier: "Asia/Kolkata"),
            ]
            workStart = 9
            workEnd = 18
        }
    }

    struct SavedState: Codable {
        var participants: [Participant]
        var workStart: Int
        var workEnd: Int
    }

    private func save() {
        let s = SavedState(participants: participants, workStart: workStart, workEnd: workEnd)
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: - time math (columns are UTC hours 0..23)
    func localMinutes(_ p: Participant, utcHour: Int) -> Int {
        let m = utcHour * 60 + p.offsetMinutes(referenceDate)
        return ((m % 1440) + 1440) % 1440
    }

    func localHour(_ p: Participant, utcHour: Int) -> Int { localMinutes(p, utcHour: utcHour) / 60 }

    func workable(_ p: Participant, utcHour: Int) -> Bool {
        let h = localHour(p, utcHour: utcHour)
        return h >= workStart && h < workEnd
    }

    func isOverlap(_ utcHour: Int) -> Bool {
        !participants.isEmpty && participants.allSatisfy { workable($0, utcHour: utcHour) }
    }

    func overlapHours() -> [Int] {
        (0..<24).filter { isOverlap($0) }
    }

    func localTimeString(_ p: Participant, utcHour: Int) -> String {
        let mins = localMinutes(p, utcHour: utcHour)
        let h = mins / 60, m = mins % 60
        let ampm = h < 12 ? "AM" : "PM"
        var hr = h % 12; if hr == 0 { hr = 12 }
        return m == 0 ? "\(hr) \(ampm)" : String(format: "%d:%02d %@", hr, m, ampm)
    }

    /// Whole-hour offset label like "UTC−7" / "UTC+5:30".
    func offsetLabel(_ p: Participant) -> String {
        let mins = p.offsetMinutes(referenceDate)
        let sign = mins < 0 ? "−" : "+"
        let a = abs(mins)
        return a % 60 == 0 ? "UTC\(sign)\(a/60)" : "UTC\(sign)\(a/60):\(String(format: "%02d", a%60))"
    }

    var currentUTCHour: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.component(.hour, from: referenceDate)
    }

    func add(city: String, tz: String) {
        participants.append(Participant(name: city, city: city, tzIdentifier: tz))
    }
    func remove(_ p: Participant) { participants.removeAll { $0.id == p.id } }
}
