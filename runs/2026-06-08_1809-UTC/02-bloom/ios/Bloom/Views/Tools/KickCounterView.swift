import SwiftUI
import SwiftData

struct KickCounterView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \KickSession.start, order: .reverse) private var sessions: [KickSession]
    @AppStorage("bloom.kickTarget") private var target = 10

    @State private var startTime: Date?
    @State private var count = 0
    @State private var finished = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                counterCard
                if finished, let s = sessions.first {
                    resultCard(s)
                }
                historyCard
            }
            .padding()
        }
        .background(Brand.pageBackground)
        .navigationTitle("Kick Counter")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var counterCard: some View {
        VStack(spacing: 16) {
            if let startTime {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(elapsedString(since: startTime, now: context.date))
                        .font(Brand.mono(22, weight: .medium)).foregroundStyle(Brand.text2)
                }
            } else {
                Text("Tap when you feel a movement")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            }

            Button(action: registerKick) {
                ZStack {
                    Circle().fill(Brand.inkGradient).frame(width: 180, height: 180)
                        .shadow(color: Brand.cardShadow, radius: 14, y: 8)
                    VStack(spacing: 2) {
                        Text("\(count)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("of \(target)").font(.caption).foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Record a kick. \(count) of \(target) counted.")

            if startTime != nil {
                Button("Reset session") { reset() }
                    .font(.subheadline.weight(.medium)).foregroundStyle(Brand.danger)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 22)
    }

    private func resultCard(_ s: KickSession) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill").font(.title).foregroundStyle(Brand.live)
            Text("10 movements in \(durationString(s.durationSeconds))")
                .font(.headline).foregroundStyle(Brand.text)
            Text("Most healthy sessions reach 10 within two hours. Mention anything unusual to your provider.")
                .font(.caption).foregroundStyle(Brand.text3).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Past sessions")
            if sessions.isEmpty {
                Text("No sessions yet.").font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                ForEach(sessions.prefix(8)) { s in
                    HStack {
                        Text(s.start.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline).foregroundStyle(Brand.text)
                        Spacer()
                        Text("\(s.count) in \(durationString(s.durationSeconds))")
                            .font(Brand.mono(12)).foregroundStyle(Brand.text2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func registerKick() {
        if startTime == nil {
            startTime = .now
            count = 0
            finished = false
        }
        count += 1
        Haptics.tap()
        if count >= target, let start = startTime {
            let s = KickSession(start: start, end: .now, count: count)
            context.insert(s)
            try? context.save()
            Haptics.success()
            finished = true
            startTime = nil
        }
    }

    private func reset() {
        startTime = nil
        count = 0
        finished = false
        Haptics.warning()
    }

    private func elapsedString(since: Date, now: Date) -> String {
        durationString(max(0, Int(now.timeIntervalSince(since))))
    }

    private func durationString(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
