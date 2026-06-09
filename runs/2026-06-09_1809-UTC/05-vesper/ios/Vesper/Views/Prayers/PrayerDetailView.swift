import SwiftUI
import SwiftData

struct PrayerDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var prayer: Prayer

    @State private var newUpdate = ""
    @State private var showAnswerSheet = false
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var didAnswer = false

    private var sortedUpdates: [PrayerUpdate] {
        prayer.updates.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if didAnswer {
                        SuccessBanner(text: "Marked answered. Thanks be.")
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if !prayer.body.isEmpty {
                        GlassCard {
                            Text(prayer.body)
                                .font(.body)
                                .foregroundStyle(Brand.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if prayer.status == .answered {
                        answeredCard
                    }

                    actionsRow
                    updatesSection
                }
                .padding(20)
            }
        }
        .navigationTitle("Prayer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Haptics.tap(); showEdit = true
                    } label: { Label("Edit", systemImage: "pencil") }

                    Button {
                        Haptics.tap()
                        withAnimation(Brand.ease()) { prayer.isPinned.toggle() }
                        try? context.save()
                    } label: {
                        Label(prayer.isPinned ? "Unpin" : "Pin", systemImage: prayer.isPinned ? "pin.slash" : "pin")
                    }

                    if prayer.status != .archived {
                        Button {
                            Haptics.tap()
                            withAnimation(Brand.ease()) { prayer.status = .archived }
                            try? context.save()
                        } label: { Label("Archive", systemImage: "archivebox") }
                    } else {
                        Button {
                            Haptics.tap()
                            withAnimation(Brand.ease()) { prayer.status = .praying }
                            try? context.save()
                        } label: { Label("Restore to praying", systemImage: "arrow.uturn.backward") }
                    }

                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: { Label("Delete", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Prayer options")
            }
        }
        .sheet(isPresented: $showEdit) {
            PrayerEditorView(prayer: prayer)
        }
        .sheet(isPresented: $showAnswerSheet) {
            answerSheet
        }
        .alert("Delete this prayer?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                context.delete(prayer)
                try? context.save()
                Haptics.warning()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the prayer and all its updates. This can't be undone.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if prayer.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundStyle(Brand.warn)
                        .accessibilityLabel("Pinned")
                }
                StatusPill(status: prayer.status)
                Spacer()
            }
            Text(prayer.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.text)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                TagChip(text: prayer.category.label, systemImage: prayer.category.symbol, tint: prayer.category.tint)
                if !prayer.personName.isEmpty {
                    TagChip(text: prayer.personName, systemImage: "person", tint: Brand.text2)
                }
            }
            Text("Held since \(prayer.createdAt.mediumString)")
                .font(Brand.mono(12))
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var answeredCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Brand.magic)
                        .accessibilityHidden(true)
                    Eyebrow(text: "Answered")
                    Spacer()
                    if let at = prayer.answeredAt {
                        Text(at.mediumString)
                            .font(Brand.mono(12))
                            .foregroundStyle(Brand.text3)
                    }
                }
                if !prayer.answeredNote.isEmpty {
                    Text(prayer.answeredNote)
                        .font(.body)
                        .foregroundStyle(Brand.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var actionsRow: some View {
        if prayer.status == .praying {
            Button {
                Haptics.tap()
                showAnswerSheet = true
            } label: {
                Label("Mark as answered", systemImage: "checkmark.seal")
            }
            .buttonStyle(InkButtonStyle())
        } else if prayer.status == .answered {
            Button {
                Haptics.tap()
                withAnimation(Brand.ease()) {
                    prayer.status = .praying
                    prayer.answeredAt = nil
                }
                try? context.save()
            } label: {
                Label("Reopen prayer", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(GlassButtonStyle())
        }
    }

    private var updatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Reflections")

            HStack(spacing: 10) {
                TextField("Add a reflection…", text: $newUpdate, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                Button {
                    addUpdate()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(canAddUpdate ? Brand.magic : Brand.text3)
                }
                .disabled(!canAddUpdate)
                .accessibilityLabel("Add reflection")
            }

            if sortedUpdates.isEmpty {
                Text("No reflections yet. Notes you add here form a quiet timeline of this prayer.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(sortedUpdates) { update in
                    GlassCard(padding: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(update.date.relativeDayPhrase)
                                .font(Brand.mono(11, weight: .medium))
                                .foregroundStyle(Brand.text3)
                            Text(update.text)
                                .font(.subheadline)
                                .foregroundStyle(Brand.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(update.date.relativeDayPhrase): \(update.text)")
                }
            }
        }
    }

    private var canAddUpdate: Bool {
        !newUpdate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addUpdate() {
        let text = newUpdate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let update = PrayerUpdate(date: .now, text: text, prayer: prayer)
        context.insert(update)
        try? context.save()
        Haptics.tap()
        withAnimation(Brand.ease()) { newUpdate = "" }
    }

    private var answerSheet: some View {
        AnswerSheet(prayer: prayer) {
            withAnimation(Brand.ease()) { didAnswer = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                withAnimation(Brand.ease()) { didAnswer = false }
            }
        }
    }
}

/// A small sheet to record how a prayer was answered.
private struct AnswerSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let prayer: Prayer
    let onAnswered: () -> Void

    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: "How was it answered?")
                        Text("Take a breath and name what happened, in your own words.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    TextField("It unfolded like this…", text: $note, axis: .vertical)
                        .lineLimit(4...10)
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))

                    Button {
                        confirm()
                    } label: {
                        Label("Mark answered", systemImage: "checkmark.seal")
                    }
                    .buttonStyle(InkButtonStyle())
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Answered")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func confirm() {
        prayer.status = .answered
        prayer.answeredAt = .now
        prayer.answeredNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        try? context.save()
        Haptics.success()
        onAnswered()
        dismiss()
    }
}
