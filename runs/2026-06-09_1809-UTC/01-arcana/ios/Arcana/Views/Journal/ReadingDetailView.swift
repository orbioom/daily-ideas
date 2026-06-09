import SwiftUI
import SwiftData

/// Shows a saved reading's spread layout with each drawn card, per-card notes,
/// an editable reflection, favorite toggle, and delete.
struct ReadingDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var reading: Reading

    @State private var note = ""
    @State private var showDeleteConfirm = false
    @State private var loadedNote = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if !reading.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Eyebrow(text: "Your question")
                            Text(reading.question)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Brand.text)
                        }
                    }
                }

                ForEach(reading.orderedCards) { drawn in
                    DrawnCardCard(drawn: drawn) { save() }
                }

                reflectionCard

                Button(role: .destructive) {
                    Haptics.warning()
                    showDeleteConfirm = true
                } label: {
                    Label("Delete reading", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                .foregroundStyle(Brand.danger)
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle(reading.spreadName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    reading.isFavorite.toggle()
                    save()
                } label: {
                    Image(systemName: reading.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(reading.isFavorite ? Brand.warn : Brand.text2)
                }
                .accessibilityLabel(reading.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
        .confirmationDialog("Delete this reading?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Haptics.warning()
                context.delete(reading)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the reading and its cards.")
        }
        .onAppear {
            if !loadedNote { note = reading.note; loadedNote = true }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(text: reading.date.formatted(date: .complete, time: .shortened))
            Text(reading.spreadName)
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reflectionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "Reflection")
                TextField("Add a note about this reading…", text: $note, axis: .vertical)
                    .lineLimit(3...8)
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                    .accessibilityLabel("Reading reflection")
                Button {
                    reading.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
                    save()
                    Haptics.success()
                } label: {
                    Label("Save note", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
    }

    private func save() {
        try? context.save()
    }
}

/// One drawn card inside a reading detail, with an editable per-card note.
private struct DrawnCardCard: View {
    @Bindable var drawn: DrawnCard
    let onChange: () -> Void

    @State private var note = ""
    @State private var loaded = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text("\(drawn.positionIndex + 1)")
                        .font(Brand.mono(13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Brand.magic, in: Circle())
                        .accessibilityHidden(true)
                    Text(drawn.positionTitle)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                }

                if let card = drawn.card {
                    CardFace(card: card, reversed: drawn.isReversed, size: .medium)
                    KeywordChips(keywords: card.keywords(reversed: drawn.isReversed))
                    Text(card.meaning(reversed: drawn.isReversed))
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Card unavailable.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                }

                TextField("Note for this card…", text: $note, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.subheadline)
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                    .accessibilityLabel("Note for \(drawn.positionTitle)")
                    .onChange(of: note) { _, new in
                        drawn.note = new.trimmingCharacters(in: .whitespacesAndNewlines)
                        onChange()
                    }
            }
        }
        .onAppear {
            if !loaded { note = drawn.note; loaded = true }
        }
    }
}
