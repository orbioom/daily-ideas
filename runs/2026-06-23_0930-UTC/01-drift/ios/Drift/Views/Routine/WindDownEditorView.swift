import SwiftUI
import SwiftData

/// Create or edit a wind-down step, with a symbol picker.
struct WindDownEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let item: WindDownItem?
    let nextOrder: Int

    @State private var title: String
    @State private var detail: String
    @State private var symbol: String
    @State private var errorMessage: String?

    private let symbolChoices = [
        "lightbulb.min.fill", "iphone.slash", "alarm.fill", "shower.fill",
        "book.fill", "wind", "thermometer.snowflake", "cup.and.saucer.fill",
        "moon.fill", "heart.fill", "leaf.fill", "music.note", "pencil.and.outline",
        "figure.mind.and.body", "drop.fill", "checkmark.circle"
    ]

    init(item: WindDownItem?, nextOrder: Int) {
        self.item = item
        self.nextOrder = nextOrder
        _title = State(initialValue: item?.title ?? "")
        _detail = State(initialValue: item?.detail ?? "")
        _symbol = State(initialValue: item?.symbol ?? "moon.fill")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Step") {
                    TextField("Title (e.g. Dim the lights)", text: $title)
                    TextField("Detail (optional)", text: $detail, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
                        ForEach(symbolChoices, id: \.self) { choice in
                            Button {
                                symbol = choice
                            } label: {
                                Image(systemName: choice)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(symbol == choice ? Theme.accent.opacity(0.2) : Theme.backgroundSecondary)
                                    .foregroundStyle(symbol == choice ? Theme.accent : Theme.textSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Icon \(choice)")
                            .accessibilityAddTraits(symbol == choice ? [.isSelected, .isButton] : .isButton)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.bad)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle(item == nil ? "New Step" : "Edit Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please give the step a title."
            return
        }
        if let item {
            item.title = trimmed
            item.detail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
            item.symbol = symbol
        } else {
            let new = WindDownItem(
                title: trimmed,
                detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
                symbol: symbol,
                order: nextOrder,
                isEnabled: true
            )
            context.insert(new)
        }
        try? context.save()
        dismiss()
    }
}
