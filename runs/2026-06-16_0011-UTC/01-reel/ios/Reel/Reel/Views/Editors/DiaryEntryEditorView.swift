import SwiftUI
import SwiftData

/// Log a new diary entry (or edit one) for a Title. Marks the Title watched and syncs its rating.
struct DiaryEntryEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let title: Title
    /// nil = adding new.
    let existing: DiaryEntry?

    @State private var watchedDate = Date()
    @State private var rating: Double = 0
    @State private var review = ""
    @State private var isRewatch = false

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        PosterView(title: title, asGradient: settings.showPostersAsGradient,
                                   showOverlay: false, cornerRadius: 8)
                            .frame(width: 44, height: 64)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title.name)
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(Theme.ink)
                            Text("\(title.kind.displayName) · \(String(title.year))")
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                    }
                }

                Section("Watch") {
                    DatePicker("Date watched", selection: $watchedDate, in: ...Date(), displayedComponents: .date)
                    Toggle("This was a rewatch", isOn: $isRewatch)
                }

                Section("Rating") {
                    HStack {
                        StarRatingControl(rating: $rating, size: 28)
                        Spacer()
                        Text(rating > 0 ? String(format: "%.1f", rating) : "—")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                            .monospacedDigit()
                    }
                }

                Section("Review") {
                    TextField("How was it? (optional)", text: $review, axis: .vertical)
                        .lineLimit(3...8)
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) { deleteEntry() } label: {
                            Label("Delete this entry", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Entry" : "Log a Watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let existing {
            watchedDate = existing.watchedDate
            rating = existing.rating
            review = existing.review
            isRewatch = existing.isRewatch
        } else {
            rating = title.rating ?? 0
        }
    }

    private func save() {
        if let existing {
            existing.watchedDate = watchedDate
            existing.rating = rating
            existing.review = review.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.isRewatch = isRewatch
        } else {
            let entry = DiaryEntry(watchedDate: watchedDate,
                                   rating: rating,
                                   review: review.trimmingCharacters(in: .whitespacesAndNewlines),
                                   isRewatch: isRewatch)
            entry.title = title
            title.entries.append(entry)
            context.insert(entry)
            // Logging a watch implies the title is watched; sync its rating if higher signal.
            if title.status == .watchlist || title.status == .watching {
                title.status = .watched
            }
            if rating > 0 { title.rating = rating }
        }
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func deleteEntry() {
        if let existing {
            context.delete(existing)
            try? context.save()
        }
        Haptics.warning(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

#Preview {
    DiaryEntryEditorView(title: Title(name: "Sample", year: 2024, kind: .movie), existing: nil)
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.empty)
}
