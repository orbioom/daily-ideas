import SwiftUI
import SwiftData

struct DevotionDetailView: View {
    @Environment(\.modelContext) private var context
    @Query private var logs: [ReadingLog]
    let devotion: Devotion

    @State private var note = ""
    @State private var showNoteField = false
    @State private var didMarkRead = false

    private var history: [ReadingLog] {
        VesperEngine.readingHistory(logs, devotionID: devotion.id)
    }
    private var readToday: Bool {
        let cal = Calendar.current
        return history.contains { cal.isDateInToday($0.date) }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if didMarkRead {
                        SuccessBanner(text: "Marked as read.")
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    VerseCard(devotion: devotion)

                    markReadSection
                    historySection
                }
                .padding(20)
            }
        }
        .navigationTitle(devotion.reference)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var markReadSection: some View {
        if readToday {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Brand.magic)
                    .accessibilityHidden(true)
                Text("You read this today.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                if showNoteField {
                    TextField("A short reflection (optional)", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                }
                HStack(spacing: 12) {
                    Button { markRead() } label: {
                        Label("Mark as read", systemImage: "checkmark")
                    }
                    .buttonStyle(InkButtonStyle())

                    Button {
                        Haptics.tap()
                        withAnimation(Brand.ease()) { showNoteField.toggle() }
                    } label: {
                        Image(systemName: showNoteField ? "text.bubble.fill" : "text.bubble")
                            .frame(maxWidth: 54)
                    }
                    .buttonStyle(GlassButtonStyle())
                    .accessibilityLabel(showNoteField ? "Hide reflection field" : "Add a reflection")
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Your history")
            if history.isEmpty {
                Text("You haven't read this one yet. When you do, it'll show up here with any reflections you write.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(history) { log in
                    GlassCard(padding: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(log.date.relativeDayPhrase)
                                .font(Brand.mono(11, weight: .medium))
                                .foregroundStyle(Brand.text3)
                            if log.note.isEmpty {
                                Text("Read")
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text2)
                            } else {
                                Text(log.note)
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(log.date.relativeDayPhrase): \(log.note.isEmpty ? "Read" : log.note)")
                }
            }
        }
    }

    private func markRead() {
        let log = ReadingLog(date: .now, devotionID: devotion.id,
                             note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(log)
        try? context.save()
        Haptics.success()
        note = ""
        withAnimation(Brand.ease()) {
            showNoteField = false
            didMarkRead = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(Brand.ease()) { didMarkRead = false }
        }
    }
}
