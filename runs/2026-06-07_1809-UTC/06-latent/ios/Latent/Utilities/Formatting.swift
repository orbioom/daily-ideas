import SwiftUI

/// Temperature unit preference, persisted in @AppStorage.
enum TempUnit: String, CaseIterable, Identifiable {
    case celsius, fahrenheit
    var id: String { rawValue }
    var label: String { self == .celsius ? "°C" : "°F" }
    var symbol: String { self == .celsius ? "°C" : "°F" }
}

/// Shared display formatting. All temperatures are *stored* in Celsius; this layer
/// converts only for display per the user's chosen unit.
enum Format {

    /// Convert a stored Celsius value to the chosen display unit.
    static func temp(_ celsius: Double, unit: TempUnit) -> Double {
        switch unit {
        case .celsius:    return celsius
        case .fahrenheit: return celsius * 9.0 / 5.0 + 32.0
        }
    }

    /// A display string like "20.0 °C" / "68.0 °F" for a stored Celsius value.
    static func tempString(_ celsius: Double, unit: TempUnit, decimals: Int = 1) -> String {
        let value = temp(celsius, unit: unit)
        return String(format: "%.\(max(0, decimals))f %@", value, unit.symbol)
    }

    /// Relative date such as "Today", "Yesterday", or a medium date string.
    static func relativeDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    /// "mm:ss" passthrough to the engine clock.
    static func clock(_ seconds: Int) -> String { DevEngine.clock(seconds) }
}

/// A compact 0–5 star display, optionally interactive.
struct StarRating: View {
    @Binding var rating: Int
    var interactive: Bool = false
    var size: CGFloat = 16

    init(rating: Binding<Int>, interactive: Bool = false, size: CGFloat = 16) {
        self._rating = rating
        self.interactive = interactive
        self.size = size
    }

    /// Read-only convenience initialiser.
    init(value: Int, size: CGFloat = 16) {
        self._rating = .constant(value)
        self.interactive = false
        self.size = size
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(i <= rating ? Brand.warn : Brand.text3)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard interactive else { return }
                        Haptics.selection()
                        rating = (rating == i) ? i - 1 : i
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue("\(rating) of 5 stars")
        .accessibilityAdjustableAction { direction in
            guard interactive else { return }
            switch direction {
            case .increment: rating = min(5, rating + 1)
            case .decrement: rating = max(0, rating - 1)
            @unknown default: break
            }
        }
    }
}
