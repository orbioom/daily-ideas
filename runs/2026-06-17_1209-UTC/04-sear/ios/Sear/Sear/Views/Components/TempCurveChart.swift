import SwiftUI
import Charts

/// A line chart of internal temperature over the cook, with the target as a rule.
struct TempCurveChart: View {
    @Environment(AppSettings.self) private var settings
    let cook: Cook

    private var logs: [TempLog] { cook.sortedLogs }

    var body: some View {
        if logs.isEmpty {
            Text("No temperature readings yet.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Chart {
                ForEach(logs) { log in
                    LineMark(
                        x: .value("Time", log.time),
                        y: .value("Temp", displayTemp(log.internalTempC))
                    )
                    .foregroundStyle(Theme.accent)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Time", log.time),
                        y: .value("Temp", displayTemp(log.internalTempC))
                    )
                    .foregroundStyle(Theme.accent)
                }
                RuleMark(y: .value("Target", displayTemp(cook.targetInternalTempC)))
                    .foregroundStyle(Theme.good.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Target \(settings.temp(cook.targetInternalTempC))")
                            .font(Theme.rounded(10, .semibold))
                            .foregroundStyle(Theme.good)
                    }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .accessibilityLabel("Internal temperature over time, target \(settings.temp(cook.targetInternalTempC))")
        }
    }

    private func displayTemp(_ celsius: Double) -> Double {
        settings.useFahrenheit ? Units.cToF(celsius) : celsius
    }
}
