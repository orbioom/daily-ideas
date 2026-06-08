import SwiftUI
import SwiftData

struct ContractionTimerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Contraction.start, order: .reverse) private var contractions: [Contraction]

    @State private var activeStart: Date?

    private var analysis: PregnancyEngine.ContractionAnalysis? {
        PregnancyEngine.analyze(contractions.sorted { $0.start < $1.start })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                timerCard
                if let a = analysis { analysisCard(a) }
                historyCard
            }
            .padding()
        }
        .background(Brand.pageBackground)
        .navigationTitle("Contractions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var timerCard: some View {
        VStack(spacing: 16) {
            if let activeStart {
                TimelineView(.periodic(from: .now, by: 0.2)) { ctx in
                    Text(durationString(max(0, Int(ctx.date.timeIntervalSince(activeStart)))))
                        .font(Brand.mono(40, weight: .semibold)).foregroundStyle(Brand.text)
                }
                Text("Contraction in progress").font(.caption).foregroundStyle(Brand.live)
            } else {
                Text(durationString(0)).font(Brand.mono(40, weight: .semibold)).foregroundStyle(Brand.text3)
                Text("Tap start when a contraction begins").font(.caption).foregroundStyle(Brand.text2)
            }

            Button(activeStart == nil ? "Start contraction" : "Stop") {
                toggle()
            }
            .buttonStyle(InkButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 20)
    }

    private func analysisCard(_ a: PregnancyEngine.ContractionAnalysis) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                stat(String(format: "%.1f min", a.averageFrequencyMinutes), "apart")
                Rectangle().fill(Brand.hairline).frame(width: 1, height: 30)
                stat(durationString(Int(a.averageDurationSeconds)), "long")
                Rectangle().fill(Brand.hairline).frame(width: 1, height: 30)
                stat("\(a.count)", "logged")
            }
            HStack(spacing: 8) {
                Image(systemName: a.meets511 ? "exclamationmark.triangle.fill" : "checkmark.circle")
                    .foregroundStyle(a.meets511 ? Brand.warn : Brand.live)
                Text(a.meets511
                     ? "Pattern resembles 5-1-1 — about 5 min apart, ~1 min long, for an hour. Consider calling your provider."
                     : "Not yet a 5-1-1 pattern. Keep timing and rest between contractions.")
                    .font(.caption).foregroundStyle(Brand.text2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .glassCard()
    }

    private func stat(_ v: String, _ l: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(.headline).foregroundStyle(Brand.text)
            Text(l).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(l): \(v)")
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(text: "Recent contractions")
                Spacer()
                if !contractions.isEmpty {
                    Button("Clear") { clearAll() }
                        .font(.caption.weight(.medium)).foregroundStyle(Brand.danger)
                }
            }
            if contractions.isEmpty {
                Text("No contractions logged.").font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                ForEach(contractions.prefix(12)) { c in
                    HStack {
                        Text(c.start.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline).foregroundStyle(Brand.text)
                        Spacer()
                        Text(durationString(c.durationSeconds))
                            .font(Brand.mono(12)).foregroundStyle(Brand.text2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func toggle() {
        if let start = activeStart {
            let dur = Int(Date().timeIntervalSince(start))
            context.insert(Contraction(start: start, durationSeconds: dur))
            try? context.save()
            activeStart = nil
            Haptics.success()
        } else {
            activeStart = .now
            Haptics.tap()
        }
    }

    private func clearAll() {
        for c in contractions { context.delete(c) }
        try? context.save()
        Haptics.warning()
    }

    private func durationString(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
