import SwiftUI
import SwiftData

struct PresetsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MeditationPreset.sortIndex) private var presets: [MeditationPreset]

    @State private var editing: MeditationPreset?
    @State private var showNew = false

    var body: some View {
        NavigationStack {
            Group {
                if presets.isEmpty {
                    EmptyStateView(icon: "slider.horizontal.3",
                                   title: "No presets",
                                   message: "Add a preset to shape your practice — a warm-up, a length, and the bells you like.")
                        .padding(20)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Brand.pageBackground)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(presets) { preset in
                                Button {
                                    Haptics.tap()
                                    editing = preset
                                } label: { row(preset) }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(20)
                    }
                    .background(Brand.pageBackground)
                }
            }
            .navigationTitle("Presets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showNew = true
                    } label: { Image(systemName: "plus") }
                    .accessibilityLabel("New preset")
                }
            }
            .sheet(item: $editing) { preset in
                PresetEditorView(preset: preset)
            }
            .sheet(isPresented: $showNew) {
                PresetEditorView(preset: nil)
            }
        }
    }

    private func row(_ preset: MeditationPreset) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Brand.magic.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: preset.startBell.symbol)
                    .foregroundStyle(Brand.magic)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(preset.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Brand.text)
                    if preset.isBuiltIn {
                        Text("BUILT-IN")
                            .font(Brand.mono(9, weight: .medium))
                            .tracking(0.8)
                            .foregroundStyle(Brand.text3)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Brand.hairline, in: Capsule())
                    }
                }
                Text(preset.subtitle)
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard(padding: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(preset.name), \(preset.subtitle)")
        .accessibilityHint("Edit preset")
    }
}
