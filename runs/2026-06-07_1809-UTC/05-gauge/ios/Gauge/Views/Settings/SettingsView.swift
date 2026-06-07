import SwiftUI
import SwiftData

/// Settings: haptics, appearance, weight unit, reference scale length, library
/// counts, an erase-all action, and an about section.
struct SettingsView: View {
    @AppStorage("gauge.haptics") private var hapticsEnabled = true
    @AppStorage("gauge.appearance") private var appearance = AppearanceMode.system.rawValue
    @AppStorage("gauge.unit") private var unitRaw = WeightUnit.pounds.rawValue
    @AppStorage("gauge.refScale") private var refScale = 25.5
    @AppStorage("gauge.hasOnboarded") private var hasOnboarded = false

    @Environment(\.modelContext) private var context
    @Query private var instruments: [Instrument]

    @State private var showEraseConfirm = false
    @State private var didErase = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 16) {
                        preferencesCard
                        referenceScaleCard
                        libraryCard
                        dataCard
                        aboutCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Erase all instruments?",
                                isPresented: $showEraseConfirm,
                                titleVisibility: .visible) {
                Button("Erase Everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes every instrument and its strings. Your preferences are kept.")
            }
        }
    }

    // MARK: - Cards

    private var preferencesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(text: "Preferences")

                Toggle(isOn: $hapticsEnabled) {
                    Label("Haptics", systemImage: "hand.tap")
                        .foregroundStyle(Brand.text)
                }
                .onChange(of: hapticsEnabled) { _, on in
                    Haptics.enabled = on
                    if on { Haptics.success() }
                }

                Divider().overlay(Brand.hairline)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Appearance", systemImage: "circle.lefthalf.filled")
                        .foregroundStyle(Brand.text)
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                }

                Divider().overlay(Brand.hairline)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Tension units", systemImage: "scalemass")
                        .foregroundStyle(Brand.text)
                    Picker("Units", selection: $unitRaw) {
                        Text("Pounds (lb)").tag(WeightUnit.pounds.rawValue)
                        Text("Kilograms (kg)").tag(WeightUnit.kilograms.rawValue)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var referenceScaleCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionTitle(text: "Library reference scale")
                    Spacer()
                    Text(String(format: "%.2f\"", refScale))
                        .font(Brand.mono(15, weight: .semibold))
                        .foregroundStyle(Brand.text)
                }
                Slider(value: $refScale, in: 12...40, step: 0.05) {
                    Text("Reference scale length")
                }
                .accessibilityValue(String(format: "%.2f inches", refScale))
                Text("Used to compute the tensions shown in the Library.")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
        }
    }

    private var libraryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Catalog")
                InfoRow(label: "Instruments", value: "\(instruments.count)", mono: true)
                InfoRow(label: "Factory sets", value: "\(StringSets.sets.count)", mono: true)
                InfoRow(label: "Tuning presets", value: "\(StringSets.tunings.count)", mono: true)
            }
        }
    }

    private var dataCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Data")
                if didErase {
                    Label("All instruments erased.", systemImage: "checkmark.circle")
                        .font(.footnote)
                        .foregroundStyle(Brand.live)
                }
                Button(role: .destructive) {
                    Haptics.warning()
                    showEraseConfirm = true
                } label: {
                    Label("Erase all instruments", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(instruments.isEmpty)

                Button {
                    Haptics.tap()
                    SampleData.seedIfEmpty(context)
                } label: {
                    Label("Restore sample data", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(!instruments.isEmpty)
            }
        }
    }

    private var aboutCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "About")
                Text("Gauge")
                    .font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
                Text("A string-tension workshop for guitarists, bassists and luthiers. All math runs on-device.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
                InfoRow(label: "Version", value: "1.0", mono: true)
                InfoRow(label: "Studio", value: "Orbioom")
                Text("Conjured, not just coded.")
                    .font(.caption.italic())
                    .foregroundStyle(Brand.text3)
            }
        }
    }

    // MARK: - Actions

    private func eraseAll() {
        Haptics.warning()
        for instrument in instruments { context.delete(instrument) }
        try? context.save()
        withAnimation(Brand.ease()) { didErase = true }
    }
}
