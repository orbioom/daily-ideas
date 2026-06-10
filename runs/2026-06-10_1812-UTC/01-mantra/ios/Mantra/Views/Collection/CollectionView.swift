import SwiftUI
import SwiftData

struct CollectionView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Affirmation.createdAt, order: .reverse) private var affirmations: [Affirmation]
    @State private var showingComposer = false
    @State private var segment = 0

    private var favorites: [Affirmation] { affirmations.filter { $0.isFavorite } }
    private var custom: [Affirmation] { affirmations.filter { $0.isCustom } }
    private var shown: [Affirmation] { segment == 0 ? favorites : custom }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 14) {
                    Picker("Section", selection: $segment) {
                        Text("Favorites").tag(0)
                        Text("My Mantras").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if shown.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: segment == 0 ? "heart" : "square.and.pencil",
                            title: segment == 0 ? "No favorites yet" : "Write your own",
                            message: segment == 0
                                ? "Tap the heart on any affirmation to keep it close."
                                : "Add a mantra in your own words — it joins your daily rotation.")
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(shown) { item in row(item) }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationTitle("Mine")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingComposer = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Write an affirmation")
                }
            }
            .sheet(isPresented: $showingComposer) {
                ComposerView()
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func row(_ item: Affirmation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.text)
                    .font(.body)
                    .foregroundStyle(Brand.text)
                HStack(spacing: 6) {
                    Image(systemName: item.category.icon)
                        .font(.caption2)
                        .foregroundStyle(item.category.tint)
                    Text(item.category.rawValue)
                        .font(Brand.mono(11))
                        .foregroundStyle(Brand.text3)
                    if item.isCustom {
                        Text("· yours")
                            .font(Brand.mono(11))
                            .foregroundStyle(Brand.text3)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                item.isFavorite.toggle()
                Haptics.selection()
                try? context.save()
            } label: {
                Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(item.isFavorite ? Brand.danger : Brand.text3)
            }
            .accessibilityLabel(item.isFavorite ? "Unfavorite" : "Favorite")
        }
        .glassCard()
        .contextMenu {
            if item.isCustom {
                Button(role: .destructive) {
                    context.delete(item)
                    try? context.save()
                    Haptics.warning()
                } label: { Label("Delete", systemImage: "trash") }
            }
        }
    }
}

struct ComposerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var category: MantraCategory = .confidence

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var valid: Bool { trimmed.count >= 3 && trimmed.count <= 220 }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Eyebrow(text: "Your words")
                        ZStack(alignment: .topLeading) {
                            if trimmed.isEmpty {
                                Text("I am…")
                                    .foregroundStyle(Brand.text3)
                                    .padding(.top, 10)
                                    .padding(.leading, 6)
                            }
                            TextEditor(text: $text)
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .foregroundStyle(Brand.text)
                        }
                        .glassCard()

                        Eyebrow(text: "Category")
                        Picker("Category", selection: $category) {
                            ForEach(MantraCategory.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(Brand.text)

                        Text("\(trimmed.count)/220")
                            .font(Brand.mono(12))
                            .foregroundStyle(trimmed.count > 220 ? Brand.danger : Brand.text3)

                        Button("Save mantra") {
                            context.insert(Affirmation(text: trimmed, category: category,
                                                       isCustom: true, isFavorite: true))
                            try? context.save()
                            Haptics.success()
                            dismiss()
                        }
                        .buttonStyle(InkButtonStyle())
                        .disabled(!valid)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Mantra")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
