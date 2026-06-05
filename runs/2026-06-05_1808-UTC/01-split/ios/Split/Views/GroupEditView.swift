import SwiftUI
import SwiftData

/// Create or edit a group. nil = new group (seeds two starter members for convenience
/// only on creation when the user adds them); editing changes name/glyph/currency.
struct GroupEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allGroups: [SplitGroup]

    let group: SplitGroup?

    @State private var name = ""
    @State private var glyph = "🧾"
    @State private var currencyCode = "USD"
    @State private var validationMessage: String?

    private var isEditing: Bool { group != nil }

    private let glyphChoices = ["🧾", "🏔️", "🏠", "🍷", "✈️", "🎉", "🏖️", "🚗", "🍽️", "⛺️", "🎟️", "🛒"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Group name", text: $name)
                        .accessibilityLabel("Group name, required")
                } header: {
                    Text("Name")
                } footer: {
                    if let validationMessage {
                        Text(validationMessage).foregroundStyle(Brand.owe)
                    }
                }

                Section("Glyph") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(glyphChoices, id: \.self) { choice in
                                Button {
                                    glyph = choice
                                } label: {
                                    Text(choice)
                                        .font(.system(size: 26))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle().fill(glyph == choice
                                                          ? Brand.glassStroke.opacity(0.5)
                                                          : Color.clear)
                                        )
                                        .overlay(
                                            Circle().strokeBorder(Brand.text,
                                                                  lineWidth: glyph == choice ? 2 : 0)
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Glyph \(choice)")
                                .accessibilityAddTraits(glyph == choice ? [.isSelected] : [])
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Currency") {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(Currency.all) { currency in
                            Text("\(currency.symbol)  \(currency.name)").tag(currency.code)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit group" : "New group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func load() {
        if let group {
            name = group.name
            glyph = group.glyph
            currencyCode = group.currencyCode
        } else {
            currencyCode = settings.defaultCurrencyCode
        }
    }

    private func save() {
        let cleanName = trimmedName
        guard !cleanName.isEmpty else {
            validationMessage = "A group needs a name."
            return
        }
        // Reject duplicate names (case-insensitive), ignoring the group being edited.
        let duplicate = allGroups.contains {
            $0.id != group?.id &&
            $0.name.compare(cleanName, options: .caseInsensitive) == .orderedSame
        }
        if duplicate {
            validationMessage = "You already have a group with that name."
            return
        }

        if let group {
            group.name = cleanName
            group.glyph = glyph
            group.currencyCode = currencyCode
        } else {
            let newGroup = SplitGroup(name: cleanName, glyph: glyph, currencyCode: currencyCode)
            context.insert(newGroup)
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
