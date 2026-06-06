import SwiftUI
import SwiftData

/// One parameter's full history: chart with ideal band, plus the reading log.
struct ParameterHistoryView: View {
    @Bindable var tank: Tank
    let parameter: WaterParameter
    @Environment(\.modelContext) private var context
    @AppStorage("tempFahrenheit") private var tempF = false
    @AppStorage("salinitySG") private var salSG = false

    private var units: Units { Units(tempFahrenheit: tempF, salinitySG: salSG) }
    private var readings: [Reading] { tank.history(parameter).reversed() }   // newest first
    private var points: [(date: Date, value: Double)] { tank.history(parameter).map { ($0.date, $0.value) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if points.isEmpty {
                    EmptyStateView(icon: "drop.degreesign", title: "No readings",
                                   message: "Log a test that includes \(parameter.name) to build a history.")
                        .glassCard()
                } else {
                    summaryCard
                    chartCard
                    logCard
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 32)
        }
        .background(Brand.pageBackground)
        .navigationTitle(parameter.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryCard: some View {
        let latest = readings.first
        let values = points.map(\.value)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                StatTile(value: latest.map { Fmt.string(parameter, $0.value, units, withUnit: false) } ?? "—",
                         label: "Latest \(Fmt.unit(parameter, units))",
                         tint: latest.map { parameter.status(for: $0.value).tint } ?? Brand.text)
                StatTile(value: values.isEmpty ? "—" : Fmt.string(parameter, values.reduce(0,+)/Double(values.count), units, withUnit: false),
                         label: "Average")
                StatTile(value: "\(points.count)", label: "Readings")
            }
            Text("Ideal range: \(Fmt.idealString(parameter, units)) \(Fmt.unit(parameter, units))")
                .font(.caption).foregroundStyle(Brand.text3)
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Trend")
            if points.count >= 2 {
                ParameterChart(parameter: parameter, points: points, units: units)
            } else {
                Text("Log at least two readings to see a trend.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
        .glassCard()
    }

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Readings")
            ForEach(readings) { r in
                HStack {
                    Circle().fill(r.status.tint).frame(width: 8, height: 8)
                    Text(r.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline).foregroundStyle(Brand.text2)
                    Spacer()
                    Text(Fmt.string(parameter, r.value, units))
                        .font(Brand.mono(15, weight: .medium)).foregroundStyle(Brand.text)
                }
                .padding(.vertical, 3)
                .contextMenu {
                    Button(role: .destructive) { delete(r) } label: { Label("Delete", systemImage: "trash") }
                }
            }
        }
        .glassCard()
    }

    private func delete(_ r: Reading) { context.delete(r); try? context.save(); Haptics.warning() }
}
