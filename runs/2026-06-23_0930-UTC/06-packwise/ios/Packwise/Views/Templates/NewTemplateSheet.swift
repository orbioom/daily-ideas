import SwiftUI
import SwiftData

/// Create a new custom template with a name, icon and optional first item.
struct NewTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var detail = ""
    @State private var symbol = "list.bullet.rectangle.portrait"

    private let symbols = [
        "list.bullet.rectangle.portrait", "bag.fill", "drop.fill", "bolt.fill",
        "beach.umbrella.fill", "briefcase.fill", "figure.hiking", "snowflake",
        "camera.fill", "figure.and.child.holdinghands", "tshirt.fill", "backpack.fill"
    ]

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { !trimmed.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Template name", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("Short description (optional)", text: $detail)
                }
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 52))], spacing: Theme.Space.md) {
                        ForEach(symbols, id: \.self) { sym in
                            Button {
                                symbol = sym
                            } label: {
                                Image(systemName: sym)
                                    .font(.title3)
                                    .frame(width: 48, height: 48)
                                    .background(symbol == sym ? Theme.primary.opacity(0.18) : Theme.background)
                                    .foregroundStyle(symbol == sym ? Theme.primary : Theme.textSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                                            .strokeBorder(symbol == sym ? Theme.primary : .clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Icon \(sym)")
                            .accessibilityAddTraits(symbol == sym ? [.isSelected] : [])
                        }
                    }
                    .padding(.vertical, Theme.Space.xs)
                }
                Section {
                    Text("You'll add items after creating the template.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("New template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") { create() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func create() {
        let template = Template(
            name: trimmed,
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
            symbol: symbol,
            isBuiltIn: false
        )
        context.insert(template)
        try? context.save()
        dismiss()
    }
}
