import SwiftUI
import SwiftData

struct PresetsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @Binding var activePreset: Preset?

    @Query(sort: \Preset.sortOrder) private var presets: [Preset]

    @State private var editing: Preset?
    @State private var showNew = false
    @State private var paywall: Pro.Reason?

    private var builtIn: [Preset] { presets.filter { $0.isBuiltIn } }
    private var custom: [Preset] { presets.filter { !$0.isBuiltIn } }

    var body: some View {
        NavigationStack {
            List {
                Section("Built-in") {
                    ForEach(builtIn) { preset in
                        PresetRow(preset: preset) { activePreset = preset }
                    }
                }
                Section {
                    if custom.isEmpty {
                        Text("No custom presets yet. Tap + to craft your own sit.")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        ForEach(custom) { preset in
                            PresetRow(preset: preset) { activePreset = preset }
                                .swipeActions {
                                    Button(role: .destructive) { delete(preset) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button { editing = preset } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }.tint(Theme.accent)
                                }
                        }
                    }
                } header: {
                    Text("Your presets")
                } footer: {
                    if !isPro {
                        Text("Free Bell keeps \(Pro.freeCustomPresetLimit) custom presets. Go Pro for unlimited.")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Presets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { attemptNew() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New preset")
                }
            }
            .sheet(isPresented: $showNew) {
                PresetEditorView(preset: nil)
            }
            .sheet(item: $editing) { preset in
                PresetEditorView(preset: preset)
            }
            .sheet(item: $paywall) { reason in PaywallView(reason: reason) }
        }
    }

    private func attemptNew() {
        if !isPro && custom.count >= Pro.freeCustomPresetLimit {
            paywall = .presetLimit
        } else {
            showNew = true
        }
    }

    private func delete(_ preset: Preset) {
        context.delete(preset)
        try? context.save()
    }
}

// MARK: - Row
private struct PresetRow: View {
    let preset: Preset
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: preset.bellValue.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.name)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(preset.subtitle)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.accent)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(preset.name). \(preset.subtitle)")
        .accessibilityHint("Begins this sit")
    }
}
