import SwiftUI
import SwiftData

/// Create or edit a custom palette. Add/remove colors via the system ColorPicker.
struct PaletteEditorView: View {
    let target: PaletteEditorTarget

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var colors: [Color] = [Color(hex: 0xC04CC8), Color(hex: 0x6FBFD0), Color(hex: 0xF2B868)]
    @State private var newColor: Color = Color(hex: 0x9ED06F)
    @State private var existing: CustomPalette?
    @State private var validationMessage: String?

    private let maxColors = 16
    private let minColors = 2

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Palette name", text: $name)
                        .font(Theme.rounded(16))
                }

                Section {
                    ForEach(Array(colors.enumerated()), id: \.offset) { index, _ in
                        HStack {
                            ColorPicker("Color \(index + 1)",
                                        selection: Binding(
                                            get: { index < colors.count ? colors[index] : .gray },
                                            set: { if index < colors.count { colors[index] = $0 } }),
                                        supportsOpacity: false)
                            if colors.count > minColors {
                                Button(role: .destructive) {
                                    if index < colors.count { colors.remove(at: index) }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(Theme.bad)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Remove color \(index + 1)")
                            }
                        }
                    }
                } header: {
                    Text("Colors (\(colors.count) of \(maxColors))")
                } footer: {
                    if let validationMessage {
                        Text(validationMessage).foregroundStyle(Theme.bad)
                    } else {
                        Text("A palette needs \(minColors)–\(maxColors) colors. Region numbers map to colors in order.")
                    }
                }

                if colors.count < maxColors {
                    Section {
                        HStack {
                            ColorPicker("New color", selection: $newColor, supportsOpacity: false)
                            Button {
                                colors.append(newColor)
                            } label: {
                                Label("Add", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }

                Section {
                    preview
                }
            }
            .navigationTitle(target.isNew ? "New palette" : "Edit palette")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear(perform: load)
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview").font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)
            let cols = [GridItem(.adaptive(minimum: 28), spacing: 6)]
            LazyVGrid(columns: cols, spacing: 6) {
                ForEach(Array(colors.enumerated()), id: \.offset) { _, c in
                    RoundedRectangle(cornerRadius: 6).fill(c).frame(height: 28)
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.hairline, lineWidth: 0.5))
                }
            }
        }
    }

    private func load() {
        if case .existing(let id) = target,
           let model = context.model(for: id) as? CustomPalette {
            existing = model
            name = model.name
            let parsed = model.colorHexes.compactMap { Color(hexString: $0) }
            if !parsed.isEmpty { colors = parsed }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationMessage = "Please give your palette a name."
            return
        }
        guard colors.count >= minColors else {
            validationMessage = "Add at least \(minColors) colors."
            return
        }
        let hexes = colors.map { $0.hexString }
        if let existing {
            existing.name = trimmed
            existing.colorHexes = hexes
        } else {
            let cp = CustomPalette(name: trimmed, colorHexes: hexes)
            context.insert(cp)
        }
        try? context.save()
        dismiss()
    }
}

private extension PaletteEditorTarget {
    var isNew: Bool { if case .new = self { return true } else { return false } }
}
