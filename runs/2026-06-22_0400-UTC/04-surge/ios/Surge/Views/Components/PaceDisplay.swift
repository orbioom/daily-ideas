import SwiftUI

struct PaceDisplay: View {
    let paceSecondsPerKm: Double
    var unit: String = "km"
    var style: DisplayStyle = .full
    var color: Color = .surgeAccent

    enum DisplayStyle {
        case full       // "5:30 /km"
        case compact    // "5:30"
        case large      // Big number display
    }

    private var formattedPace: String {
        PaceEngine.formatPace(paceSecondsPerKm, unit: unit)
    }

    private var paceShort: String {
        PaceEngine.formatPaceShort(paceSecondsPerKm, unit: unit)
    }

    var body: some View {
        switch style {
        case .full:
            Text(formattedPace)
                .font(.surgeMonospace)
                .foregroundColor(paceSecondsPerKm > 0 ? color : .surgeTextSecondary)

        case .compact:
            Text(paceShort)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(paceSecondsPerKm > 0 ? color : .surgeTextSecondary)

        case .large:
            VStack(spacing: 2) {
                Text(paceShort)
                    .font(.surgeLargeNumber)
                    .foregroundColor(paceSecondsPerKm > 0 ? color : .surgeTextSecondary)
                Text("/\(unit)")
                    .font(.surgeCaption)
                    .foregroundColor(.surgeTextSecondary)
            }
        }
    }
}

struct DurationDisplay: View {
    let seconds: Int
    var style: DisplayStyle = .standard

    enum DisplayStyle {
        case standard
        case large
    }

    var body: some View {
        switch style {
        case .standard:
            Text(PaceEngine.formatDuration(seconds))
                .font(.surgeMonospace)
                .foregroundColor(seconds > 0 ? .surgeTextPrimary : .surgeTextSecondary)
        case .large:
            Text(PaceEngine.formatDuration(seconds))
                .font(.surgeLargeNumber)
                .foregroundColor(seconds > 0 ? .surgeTextPrimary : .surgeTextSecondary)
        }
    }
}

struct DistanceDisplay: View {
    let km: Double
    var unit: String = "km"
    var style: DisplayStyle = .standard

    enum DisplayStyle {
        case standard
        case large
    }

    private var displayValue: String {
        PaceEngine.formatDistance(km, unit: unit)
    }

    var body: some View {
        switch style {
        case .standard:
            Text(displayValue)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(km > 0 ? .surgeTextPrimary : .surgeTextSecondary)
        case .large:
            Text(displayValue)
                .font(.surgeLargeNumber)
                .foregroundColor(km > 0 ? .surgeTextPrimary : .surgeTextSecondary)
        }
    }
}
