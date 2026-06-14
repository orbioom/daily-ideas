import SwiftUI
import SwiftData

/// Create a new budget category (name, group, emoji, rollover).
struct AddCategorySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query private var categories: [Category]

    @State private var name = ""
    @State private var group: CategoryGroup = .food
    @State private var emoji = "💸"
    @State private var rollover = true
    @State private var didSetRolloverDefault = false

    private let emojiChoices = ["💸", "🏠", "🛒", "🍔", "☕️", "⛽️", "🚆", "🎬", "🛍️", "🛟", "✈️", "💳", "💡", "📱", "🎁", "🏥", "🐶", "🎓"]

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    TextField("Name (e.g. Groceries)", text: $name)
                    Picker("Group", selection: $group) {
                        ForEach(CategoryGroup.allCases) { g in
                            Label(g.label, systemImage: g.symbol).tag(g)
                        }
                    }
                    Toggle("Roll unspent money over", isOn: $rollover)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(emojiChoices, id: \.self) { choice in
                            Button {
                                Haptics.tap(settings.hapticsEnabled)
                                emoji = choice
                            } label: {
                                Text(choice)
                                    .font(.system(size: 24))
                                    .frame(width: 42, height: 42)
                                    .background(
                                        Circle().fill(emoji == choice ? Theme.accentSoft : Theme.surfaceAlt)
                                    )
                                    .overlay(
                                        Circle().stroke(emoji == choice ? Theme.accent : .clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Icon \(choice)")
                            .accessibilityAddTraits(emoji == choice ? [.isSelected] : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if !didSetRolloverDefault {
                    rollover = settings.defaultRollover
                    didSetRolloverDefault = true
                }
            }
        }
    }

    private func save() {
        guard canSave else { return }
        let nextOrder = (categories.map { $0.sortOrder }.max() ?? -1) + 1
        let cat = Category(name: trimmedName, group: group, emoji: emoji, rollover: rollover, sortOrder: nextOrder)
        context.insert(cat)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
