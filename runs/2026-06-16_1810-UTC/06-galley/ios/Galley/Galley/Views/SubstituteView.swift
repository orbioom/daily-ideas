import SwiftUI
import SwiftData

struct SubstituteView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false
    @Query(sort: \SubstitutionEntry.ingredient) private var entries: [SubstitutionEntry]

    @State private var search = ""
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @State private var showingAdd = false

    private var filtered: [SubstitutionEntry] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return entries }
        return entries.filter {
            $0.ingredient.lowercased().contains(q) ||
            $0.options.contains { $0.text.lowercased().contains(q) }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GalleyBackground()
                if entries.isEmpty {
                    EmptyStateView(
                        symbol: "arrow.triangle.2.circlepath",
                        title: "No substitutions",
                        message: "Substitutions will appear here once they load."
                    )
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: search)
                } else {
                    list
                }
            }
            .navigationTitle("Substitute")
            .searchable(text: $search, prompt: "Search ingredient or sub")
            .toolbar {
                settingsToolbar($showingSettings)
                ToolbarItem(placement: .topBarLeading) {
                    Button { addTapped() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add custom substitution")
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .sheet(isPresented: $showingAdd) { CustomSubstitutionEditor() }
            .navigationDestination(for: SubstitutionEntry.self) { entry in
                SubstitutionDetailView(entry: entry)
            }
        }
    }

    private var list: some View {
        List {
            ForEach(filtered) { entry in
                NavigationLink(value: entry) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.ingredient)
                                .font(.headline)
                                .foregroundStyle(GalleyTheme.primaryText(scheme))
                            Text("\(entry.options.count) alternative\(entry.options.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(GalleyTheme.secondaryText(scheme))
                        }
                        Spacer()
                        if entry.isCustom { ProBadge() }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(entry.ingredient), \(entry.options.count) alternatives\(entry.isCustom ? ", custom" : "")")
                }
                .swipeActions {
                    if entry.isCustom {
                        Button(role: .destructive) { delete(entry) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func addTapped() {
        if isPro { showingAdd = true } else { showingPaywall = true }
    }

    private func delete(_ entry: SubstitutionEntry) {
        context.delete(entry)
        try? context.save()
    }
}

struct SubstitutionDetailView: View {
    @Environment(\.colorScheme) private var scheme
    let entry: SubstitutionEntry

    var body: some View {
        ZStack {
            GalleyBackground()
            ScrollView {
                VStack(spacing: 16) {
                    GalleyCard {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(entry.ingredient)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(GalleyTheme.primaryText(scheme))
                                if entry.isCustom { ProBadge() }
                            }
                            if !entry.note.isEmpty {
                                Text(entry.note)
                                    .font(.subheadline)
                                    .foregroundStyle(GalleyTheme.secondaryText(scheme))
                            }
                        }
                    }
                    GalleyCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionLabel(text: "Alternatives")
                            ForEach(entry.orderedOptions) { opt in
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(GalleyTheme.sage)
                                            .accessibilityHidden(true)
                                        Text(opt.text)
                                            .foregroundStyle(GalleyTheme.primaryText(scheme))
                                    }
                                    if !opt.ratioNote.isEmpty {
                                        Text(opt.ratioNote)
                                            .font(.caption)
                                            .foregroundStyle(GalleyTheme.secondaryText(scheme))
                                            .padding(.leading, 26)
                                    }
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(opt.text)\(opt.ratioNote.isEmpty ? "" : ", \(opt.ratioNote)")")
                                if opt.id != entry.orderedOptions.last?.id {
                                    Divider().background(GalleyTheme.hairline(scheme))
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Substitution")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Pro-gated editor to add a custom substitution with up to several options.
struct CustomSubstitutionEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context

    @State private var ingredient = ""
    @State private var note = ""
    @State private var optionTexts: [String] = [""]
    @State private var optionRatios: [String] = [""]

    private var canSave: Bool {
        !ingredient.trimmingCharacters(in: .whitespaces).isEmpty &&
        optionTexts.contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient") {
                    TextField("e.g. Coconut Cream", text: $ingredient)
                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
                Section("Alternatives") {
                    ForEach(optionTexts.indices, id: \.self) { i in
                        VStack(alignment: .leading, spacing: 6) {
                            TextField("Alternative \(i + 1)", text: $optionTexts[i])
                            TextField("Ratio / note", text: $optionRatios[i])
                                .font(.caption)
                                .foregroundStyle(GalleyTheme.secondaryText(scheme))
                        }
                    }
                    Button {
                        optionTexts.append("")
                        optionRatios.append("")
                    } label: {
                        Label("Add alternative", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Custom Substitution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let entry = SubstitutionEntry(
            ingredient: ingredient.trimmingCharacters(in: .whitespaces),
            note: note.trimmingCharacters(in: .whitespaces),
            isCustom: true
        )
        var order = 0
        for i in optionTexts.indices {
            let text = optionTexts[i].trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { continue }
            let ratio = i < optionRatios.count ? optionRatios[i].trimmingCharacters(in: .whitespaces) : ""
            entry.options.append(SubstituteOption(text: text, ratioNote: ratio, sortOrder: order))
            order += 1
        }
        context.insert(entry)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
