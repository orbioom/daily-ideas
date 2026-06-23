import SwiftUI
import SwiftData

struct PantryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PantryStaple.name) private var staples: [PantryStaple]
    @Query private var settingsList: [AppSettings]

    @State private var showingAdd = false

    private var settings: AppSettings { settingsList.first ?? AppSettings() }
    private var onHandCount: Int { staples.filter { $0.haveOnHand }.count }

    private var grouped: [(aisle: Aisle, items: [PantryStaple])] {
        let byAisle = Dictionary(grouping: staples, by: { $0.aisle })
        return Aisle.allCases.sorted { $0.order < $1.order }.compactMap { aisle in
            guard let list = byAisle[aisle], !list.isEmpty else { return nil }
            return (aisle, list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if staples.isEmpty {
                    EmptyStateView(
                        icon: "cabinet",
                        title: "Pantry is empty",
                        message: "Add staples you usually keep on hand. Suppr leaves the ones you have off your grocery list.",
                        actionTitle: "Add a staple",
                        action: { showingAdd = true }
                    )
                } else {
                    content
                }
            }
            .navigationTitle("Pantry")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true; Haptics.tap() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add staple")
                }
            }
            .sheet(isPresented: $showingAdd) { AddPantryStapleSheet() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 14) {
                banner
                ForEach(grouped, id: \.aisle) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: group.aisle.symbol)
                                .foregroundStyle(Theme.sage)
                                .accessibilityHidden(true)
                            Text(group.aisle.rawValue)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.primaryText)
                            Spacer()
                        }
                        ForEach(group.items) { staple in
                            PantryRow(staple: staple)
                            if staple.id != group.items.last?.id {
                                Divider().overlay(Theme.hairline)
                            }
                        }
                    }
                    .cardSurface()
                }
            }
            .padding()
            .padding(.bottom, 24)
        }
    }

    private var banner: some View {
        HStack(spacing: 12) {
            Image(systemName: settings.pantryAwareList ? "checkmark.shield.fill" : "shield.slash")
                .font(.title3)
                .foregroundStyle(settings.pantryAwareList ? Theme.sage : Theme.secondaryText)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(settings.pantryAwareList ? "Pantry-aware list is on" : "Pantry-aware list is off")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.primaryText)
                Text(settings.pantryAwareList
                     ? "\(onHandCount) on-hand staples are hidden from your grocery list."
                     : "Turn it on in Settings to skip what you already have.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .cardSurface()
    }
}

struct PantryRow: View {
    @Bindable var staple: PantryStaple
    @Environment(\.modelContext) private var context

    var body: some View {
        Toggle(isOn: Binding(
            get: { staple.haveOnHand },
            set: { newVal in
                staple.haveOnHand = newVal
                try? context.save()
                Haptics.selection()
            }
        )) {
            VStack(alignment: .leading, spacing: 1) {
                Text(staple.name)
                    .font(.subheadline)
                    .foregroundStyle(Theme.primaryText)
                Text(staple.haveOnHand ? "Have it" : "Need to buy")
                    .font(.caption2)
                    .foregroundStyle(staple.haveOnHand ? Theme.sage : Theme.amber)
            }
        }
        .tint(Theme.sage)
        .accessibilityHint("Toggles whether this staple is on hand")
        .swipeActions {
            Button(role: .destructive) {
                context.delete(staple)
                try? context.save()
                Haptics.warning()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

/// Add a new pantry staple.
struct AddPantryStapleSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var aisle: Aisle = .pantry
    @State private var haveOnHand = true
    @State private var showValidation = false

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Staple") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    if showValidation && trimmed.isEmpty {
                        Label("Enter a name.", systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(Theme.terracotta)
                    }
                    Picker("Aisle", selection: $aisle) {
                        ForEach(Aisle.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
                    }
                    .pickerStyle(.navigationLink)
                    Toggle("I have this on hand", isOn: $haveOnHand)
                        .tint(Theme.sage)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Add Staple")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }.disabled(trimmed.isEmpty).fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        guard !trimmed.isEmpty else { showValidation = true; Haptics.warning(); return }
        context.insert(PantryStaple(name: trimmed, aisle: aisle, haveOnHand: haveOnHand))
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
