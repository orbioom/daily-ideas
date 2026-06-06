import SwiftUI
import SwiftData

struct StatTile: View {
    let value: String
    let label: String
    var accent: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(Brand.mono(22, weight: .semibold)).foregroundStyle(accent)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label.uppercased()).font(Brand.mono(11, weight: .medium)).tracking(1.0)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct Chip: View {
    let text: String
    var system: String? = nil
    var tint: Color = Brand.text2
    var body: some View {
        HStack(spacing: 4) {
            if let system { Image(systemName: system).font(.caption2).accessibilityHidden(true) }
            Text(text).font(Brand.mono(12, weight: .medium))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Brand.hairline, lineWidth: 1))
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View { Eyebrow(text: title).padding(.horizontal, 4).padding(.top, 4) }
}

/// Edits a duration (bound seconds) via hours/minutes/seconds fields.
struct DurationField: View {
    @Binding var totalSeconds: Double
    @State private var h = ""
    @State private var m = ""
    @State private var s = ""

    var body: some View {
        HStack(spacing: 6) {
            field($h, "h", width: 44)
            Text(":").foregroundStyle(Brand.text3)
            field($m, "mm", width: 44)
            Text(":").foregroundStyle(Brand.text3)
            field($s, "ss", width: 44)
        }
        .onAppear(perform: sync)
        .onChange(of: totalSeconds) { _, _ in sync() }
    }

    private func field(_ text: Binding<String>, _ placeholder: String, width: CGFloat) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.numberPad).multilineTextAlignment(.center)
            .font(Brand.mono(18)).frame(width: width)
            .onChange(of: text.wrappedValue) { _, _ in recompute() }
    }
    private func sync() {
        let t = Int(totalSeconds.rounded())
        h = t / 3600 > 0 ? String(t / 3600) : ""
        m = String((t % 3600) / 60)
        s = String(t % 60)
    }
    private func recompute() {
        let hi = Int(h) ?? 0, mi = min(Int(m) ?? 0, 999), si = min(Int(s) ?? 0, 59)
        totalSeconds = Double(hi * 3600 + mi * 60 + si)
    }
}

/// A shared benchmark editor: pick a distance and a time. The benchmark drives
/// the Predict, Paces, and Plan calculators so they stay consistent.
struct BenchmarkCard: View {
    @Binding var meters: Double
    @Binding var seconds: Double
    @Query(sort: \Run.date, order: .reverse) private var runs: [Run]

    private var races: [Run] { runs.filter { $0.kind == .race && $0.distanceMeters > 0 } }
    private var distanceName: String {
        PaceMath.standardDistances.min { abs($0.meters - meters) < abs($1.meters - meters) }?.name ?? "Custom"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow(text: "Benchmark performance")
                Spacer()
                if !races.isEmpty {
                    Menu {
                        ForEach(races) { r in
                            Button("\(r.name) · \(PaceMath.clock(r.durationSeconds))") {
                                meters = r.distanceMeters; seconds = r.durationSeconds; Haptics.selection()
                            }
                        }
                    } label: { Label("From race", systemImage: "flag.checkered").font(.footnote) }
                }
            }
            Picker("Distance", selection: $meters) {
                ForEach(PaceMath.standardDistances, id: \.meters) { Text($0.name).tag($0.meters) }
            }
            .pickerStyle(.menu)
            HStack {
                Text("Time").foregroundStyle(Brand.text2)
                Spacer()
                DurationField(totalSeconds: $seconds)
            }
            Text("\(distanceName) in \(PaceMath.clock(seconds))")
                .font(.footnote).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
    }
}
