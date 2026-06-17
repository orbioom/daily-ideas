import SwiftUI

struct PaletteEditorResult {
    let name: String
    let hexes: [String]
}

/// Create or edit a custom palette: name + add / remove / reorder colors via a color picker.
struct PaletteEditorView: View {
    let existing: CustomPalette?
    var onComplete: (PaletteEditorResult?) -> Void

    @EnvironmentObject private var settings: AppSettings
    @State private var name: String
    @State private var colors: [Color]

    init(existing: CustomPalette?, onComplete: @escaping (PaletteEditorResult?) -> Void) {
        self.existing = existing
        self.onComplete = onComplete
        _name = State(initialValue: existing?.name ?? "")
        let initialHexes = existing?.hexes ?? ["7C5CFF", "A690FF", "C2E9FB"]
        _colors = State(initialValue: initialHexes.compactMap { WallpaperSpec.hexValue($0) }.map { Color(hex: $0) })
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !colors.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Palette name", text: $name)
                        .font(Theme.rounded(16))
                }

                Section("Preview") {
                    SwatchRow(colors: colors, height: 40)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("Colors") {
                    ForEach(Array(colors.enumerated()), id: \.offset) { index, _ in
                        HStack(spacing: 12) {
                            ColorPicker(
                                "Color \(index + 1)",
                                selection: Binding(
                                    get: { colors[safe: index] ?? .black },
                                    set: { if colors.indices.contains(index) { colors[index] = $0 } }
                                ),
                                supportsOpacity: false
                            )
                            .labelsHidden()
                            Text("Color \(index + 1)")
                                .font(Theme.rounded(15))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            if colors.count > 1 {
                                Button(role: .destructive) {
                                    removeColor(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(Theme.bad)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Remove color \(index + 1)")
                            }
                        }
                    }
                    .onMove(perform: moveColor)

                    Button {
                        addColor()
                    } label: {
                        Label("Add color", systemImage: "plus.circle.fill")
                            .foregroundStyle(Theme.accent)
                    }
                    .disabled(colors.count >= 8)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .environment(\.editMode, .constant(.active))
            .navigationTitle(existing == nil ? "New Palette" : "Edit Palette")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onComplete(nil) }
                        .foregroundStyle(Theme.inkSoft)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(Theme.rounded(16, .semibold))
                        .disabled(!canSave)
                }
            }
        }
    }

    private func addColor() {
        guard colors.count < 8 else { return }
        Haptics.selection(enabled: settings.hapticsEnabled)
        colors.append(Theme.accentSoft)
    }

    private func removeColor(at index: Int) {
        guard colors.indices.contains(index), colors.count > 1 else { return }
        Haptics.selection(enabled: settings.hapticsEnabled)
        colors.remove(at: index)
    }

    private func moveColor(from source: IndexSet, to destination: Int) {
        colors.move(fromOffsets: source, toOffset: destination)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !colors.isEmpty else { return }
        let hexes = colors.map { color -> String in
            let ui = UIColor(color)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            ui.getRed(&r, green: &g, blue: &b, alpha: &a)
            let value = (UInt(max(0, min(255, r * 255))) << 16)
                | (UInt(max(0, min(255, g * 255))) << 8)
                | UInt(max(0, min(255, b * 255)))
            return WallpaperSpec.hexString(from: value)
        }
        onComplete(PaletteEditorResult(name: trimmed, hexes: hexes))
    }
}
