import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var prayers: [Prayer]
    @Query private var logs: [ReadingLog]

    @AppStorage("vesper.eveningExamen") private var eveningExamen = false

    @State private var reflection = ""
    @State private var showReflectionField = false
    @State private var didMarkRead = false
    @State private var showNewPrayer = false
    @State private var selectedPrayer: Prayer?

    private var devotion: Devotion { VesperEngine.devotion(for: .now) }

    private var todaysLog: ReadingLog? {
        let cal = Calendar.current
        return logs.first { $0.devotionID == devotion.id && cal.isDateInToday($0.date) }
    }

    private var streak: Int { VesperEngine.currentStreak(prayers, logs) }
    private var readingsMonth: Int { VesperEngine.readingsThisMonth(logs) }
    private var needsPrayer: [Prayer] { VesperEngine.needingAttention(prayers, days: 14, limit: 4) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        greeting

                        if didMarkRead {
                            SuccessBanner(text: "Marked as read. Rest well.")
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        devotionSection
                        statsRow
                        if eveningExamen { examenCard }
                        needsPrayerSection
                        quickAddButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide)))
                        .font(Brand.mono(13))
                        .foregroundStyle(Brand.text2)
                }
            }
            .sheet(isPresented: $showNewPrayer) {
                PrayerEditorView()
            }
            .navigationDestination(item: $selectedPrayer) { prayer in
                PrayerDetailView(prayer: prayer)
            }
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(text: timeOfDayGreeting)
            Text(Date.now.formatted(.dateTime.month(.wide).day()))
                .font(.title.weight(.bold))
                .foregroundStyle(Brand.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "A quiet night"
        }
    }

    private var devotionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Devotion of the day")
            VerseCard(devotion: devotion)

            if let log = todaysLog {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Brand.magic)
                        .accessibilityHidden(true)
                    Text(log.note.isEmpty ? "Read today." : "Read today — “\(log.note)”")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                if showReflectionField {
                    TextField("A short reflection (optional)", text: $reflection, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                }
                HStack(spacing: 12) {
                    Button {
                        markRead()
                    } label: {
                        Label("Mark as read", systemImage: "checkmark")
                    }
                    .buttonStyle(InkButtonStyle())

                    Button {
                        Haptics.tap()
                        withAnimation(Brand.ease()) { showReflectionField.toggle() }
                    } label: {
                        Image(systemName: showReflectionField ? "text.bubble.fill" : "text.bubble")
                            .frame(maxWidth: 54)
                    }
                    .buttonStyle(GlassButtonStyle())
                    .accessibilityLabel(showReflectionField ? "Hide reflection field" : "Add a reflection")
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(streak)", label: "Day streak", tint: Brand.magic)
            StatTile(value: "\(readingsMonth)", label: "Read this month")
        }
    }

    private var examenCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .foregroundStyle(Brand.info)
                        .accessibilityHidden(true)
                    Eyebrow(text: "Evening examen")
                }
                Text("Where did you notice grace today? What do you want to release before you sleep?")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var needsPrayerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Needs prayer")
            if needsPrayer.isEmpty {
                GlassCard {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(Brand.magic)
                            .accessibilityHidden(true)
                        Text("Every active prayer has been touched recently. Beautifully tended.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                GlassCard(padding: 8) {
                    VStack(spacing: 0) {
                        ForEach(needsPrayer) { prayer in
                            Button {
                                Haptics.tap()
                                selectedPrayer = prayer
                            } label: {
                                HStack {
                                    PrayerRow(prayer: prayer)
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Brand.text3)
                                        .accessibilityHidden(true)
                                }
                                .padding(.horizontal, 8)
                            }
                            .buttonStyle(.plain)
                            if prayer.id != needsPrayer.last?.id {
                                Divider().overlay(Brand.hairline).padding(.leading, 8)
                            }
                        }
                    }
                }
            }
        }
    }

    private var quickAddButton: some View {
        Button {
            Haptics.tap()
            showNewPrayer = true
        } label: {
            Label("New prayer", systemImage: "plus")
        }
        .buttonStyle(InkButtonStyle())
        .padding(.top, 4)
    }

    private func markRead() {
        let log = ReadingLog(date: .now, devotionID: devotion.id,
                             note: reflection.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(log)
        try? context.save()
        Haptics.success()
        reflection = ""
        withAnimation(Brand.ease()) {
            showReflectionField = false
            didMarkRead = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(Brand.ease()) { didMarkRead = false }
        }
    }
}
