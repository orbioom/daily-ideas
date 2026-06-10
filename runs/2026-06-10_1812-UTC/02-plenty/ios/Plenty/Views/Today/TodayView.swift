import SwiftUI
import SwiftData

enum RitualPhase: String { case morning, evening }

struct EditTarget: Identifiable {
    let id = UUID()
    let day: GratitudeDay
    let phase: RitualPhase
}

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var days: [GratitudeDay]
    @State private var target: EditTarget?

    private var todayKey: Int { PlentyEngine.dayKey(.now) }
    private var todayEntry: GratitudeDay? { days.first { $0.dayKey == todayKey } }
    private var streak: Int { PlentyEngine.currentStreak(days: days) }

    private var morningDone: Bool { todayEntry?.morningDone ?? false }
    private var eveningDone: Bool { todayEntry?.eveningDone ?? false }
    private var isEvening: Bool { Calendar.current.component(.hour, from: .now) >= 17 }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        ritualCard(.morning, done: morningDone,
                                   title: "Morning ritual",
                                   subtitle: "Three gratitudes and an intention",
                                   icon: "sunrise.fill", tint: Brand.warn)
                        ritualCard(.evening, done: eveningDone,
                                   title: "Evening reflection",
                                   subtitle: "Three good things and a mood",
                                   icon: "moon.stars.fill", tint: Brand.info)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 6) {
                        Image(systemName: "leaf.fill").foregroundStyle(streak > 0 ? Brand.live : Brand.text3)
                        Text("\(streak)").font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Gratitude streak \(streak) days")
                }
            }
            .sheet(item: $target) { t in
                EntryEditorView(day: t.day, phase: t.phase)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(text: Date.now.formatted(.dateTime.weekday(.wide).month().day()))
            Text(isEvening ? "How did today treat you?" : "What are you grateful for?")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Brand.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func ritualCard(_ phase: RitualPhase, done: Bool, title: String, subtitle: String,
                            icon: String, tint: Color) -> some View {
        Button {
            Haptics.tap()
            target = EditTarget(day: ensureToday(), phase: phase)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: done ? "checkmark.circle.fill" : icon)
                    .font(.title)
                    .foregroundStyle(done ? Brand.live : tint)
                    .frame(width: 54, height: 54)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).foregroundStyle(Brand.text)
                    Text(done ? "Done — tap to revisit" : subtitle)
                        .font(.subheadline).foregroundStyle(Brand.text2)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Brand.text3)
            }
            .glassCard()
        }
        .buttonStyle(.plain)
        .accessibilityHint(done ? "Completed" : "Not started")
    }

    /// Fetch today's entry or create it lazily.
    private func ensureToday() -> GratitudeDay {
        if let existing = todayEntry { return existing }
        let new = GratitudeDay(date: .now)
        context.insert(new)
        try? context.save()
        return new
    }
}
