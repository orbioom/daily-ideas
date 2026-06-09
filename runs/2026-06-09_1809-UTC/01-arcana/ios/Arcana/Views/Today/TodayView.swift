import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(PrefKey.allowReversed) private var allowReversed = true

    @Query private var readings: [Reading]

    @State private var reflection = ""
    @State private var savedToday = false
    @State private var showSettings = false
    @State private var startReadingFlow = false

    private var daily: (card: TarotCard, reversed: Bool) {
        ArcanaEngine.dailyCard(for: .now, allowReversed: allowReversed)
    }

    /// The reading saved today from the daily-card reflection, if any.
    private var todaysDailyReading: Reading? {
        let cal = Calendar.current
        return readings.first { r in
            r.spreadName == SpreadCatalog.all[0].name &&
            cal.isDateInToday(r.date) &&
            r.cards.first?.cardID == daily.card.id
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                CardFace(card: daily.card, reversed: daily.reversed, size: .large)

                KeywordChips(keywords: daily.card.keywords(reversed: daily.reversed))

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: daily.reversed ? "Reversed meaning" : "Upright meaning")
                        Text(daily.card.meaning(reversed: daily.reversed))
                            .font(.body)
                            .foregroundStyle(Brand.text2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                reflectionCard

                Button {
                    Haptics.tap()
                    startReadingFlow = true
                } label: {
                    Label("New Reading", systemImage: "sparkles")
                }
                .buttonStyle(InkButtonStyle())
                .accessibilityHint("Opens the reading flow to pick a spread")
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
        .navigationDestination(isPresented: $startReadingFlow) {
            SpreadPickerView()
        }
        .onAppear {
            if let existing = todaysDailyReading { reflection = existing.note; savedToday = true }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(text: Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
            Text("Card of the Day")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Brand.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reflectionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Today's reflection")
                Text("Capture a thought on what this card means for you. Saved as today's reading.")
                    .font(.footnote)
                    .foregroundStyle(Brand.text3)

                TextField("How does this land for you?", text: $reflection, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                    .accessibilityLabel("Today's reflection")

                HStack(spacing: 12) {
                    Button {
                        saveReflection()
                    } label: {
                        Label(savedToday ? "Update reflection" : "Save reflection", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(GlassButtonStyle())

                    if savedToday {
                        Label("Saved", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.magic)
                            .accessibilityLabel("Reflection saved")
                    }
                }
            }
        }
    }

    private func saveReflection() {
        Haptics.success()
        let trimmed = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = todaysDailyReading {
            existing.note = trimmed
        } else {
            let reading = Reading(date: .now, spreadName: SpreadCatalog.all[0].name, note: trimmed)
            context.insert(reading)
            let drawn = DrawnCard(positionIndex: 0,
                                  positionTitle: SpreadCatalog.all[0].positions[0].title,
                                  cardID: daily.card.id,
                                  isReversed: daily.reversed)
            drawn.reading = reading
            context.insert(drawn)
        }
        try? context.save()
        withAnimation(Brand.ease()) { savedToday = true }
    }
}
