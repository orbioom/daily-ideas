import SwiftUI
import SwiftData

/// A quick daily mood + note check-in. Creates (or updates today's) JournalEntry.
struct CheckInView: View {
    let profile: Profile
    let reading: DailyReading

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query private var allEntries: [JournalEntry]

    @State private var mood = 3
    @State private var note = ""
    @State private var saved = false

    private let moods: [(value: Int, symbol: String, label: String)] = [
        (1, "cloud.rain.fill", "Heavy"),
        (2, "cloud.fill", "Low"),
        (3, "cloud.sun.fill", "Steady"),
        (4, "sun.max.fill", "Bright"),
        (5, "sparkles", "Radiant")
    ]

    private var todaysEntry: JournalEntry? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return allEntries.first {
            $0.profileName == profile.name && cal.startOfDay(for: $0.date) == today
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    moonHeader
                    moodPicker
                    noteField
                    PrimaryButton(title: "Save reflection", systemImage: "checkmark") {
                        save()
                    }
                    if saved {
                        Label("Saved. See you tomorrow.", systemImage: "checkmark.seal.fill")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.good)
                            .transition(.opacity)
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Check in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let existing = todaysEntry {
                    mood = existing.mood
                    note = existing.note
                }
            }
        }
    }

    private var moonHeader: some View {
        VStack(spacing: 6) {
            GlyphBadge(glyph: reading.moonSign.glyph, tint: Theme.gold, size: 52)
            Text("Moon in \(reading.moonSign.name)")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
            if let t = reading.strongest {
                Text(t.headline)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var moodPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "How are you?", systemImage: "heart.fill")
            HStack(spacing: 8) {
                ForEach(moods, id: \.value) { m in
                    Button {
                        mood = m.value
                        Haptics.selection(enabled: settings.hapticsEnabled)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: m.symbol)
                                .font(.system(size: 22))
                            Text(m.label)
                                .font(Theme.rounded(11, .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(mood == m.value ? .white : Theme.inkSoft)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                                .fill(mood == m.value ? Theme.accent : Theme.surfaceAlt)
                        )
                    }
                    .buttonStyle(PressableScale())
                    .accessibilityLabel(m.label)
                    .accessibilityAddTraits(mood == m.value ? .isSelected : [])
                }
            }
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "A note (optional)", systemImage: "square.and.pencil")
            TextField("What's on your mind?", text: $note, axis: .vertical)
                .font(Theme.rounded(16))
                .lineLimit(3...6)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                        .fill(Theme.surfaceAlt)
                )
        }
    }

    private func save() {
        let summary = reading.strongest?.headline ?? "Moon in \(reading.moonSign.name)"
        if let existing = todaysEntry {
            existing.mood = min(max(mood, 1), 5)
            existing.note = note
            existing.transitSummary = summary
        } else {
            let entry = JournalEntry(date: Date(),
                                     mood: mood,
                                     note: note,
                                     transitSummary: summary,
                                     profileName: profile.name)
            modelContext.insert(entry)
        }
        try? modelContext.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}
