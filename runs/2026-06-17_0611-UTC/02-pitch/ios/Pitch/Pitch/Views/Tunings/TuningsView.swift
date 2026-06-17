import SwiftUI
import SwiftData

/// Tunings screen: choose the active tuning from built-in + custom presets,
/// and (Pro) create custom tunings.
struct TuningsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CustomTuning.createdAt) private var customTunings: [CustomTuning]

    @AppStorage("activeTuningID") private var activeTuningID: String = TuningCatalog.defaultID
    @AppStorage("isPro") private var isPro: Bool = false
    @AppStorage("hapticOnBeat") private var haptics: Bool = true

    @State private var showBuilder = false
    @State private var showPaywall = false

    /// Built-in tunings grouped by instrument family for tidy sections.
    private var grouped: [(InstrumentKind, [Tuning])] {
        InstrumentKind.allCases.compactMap { kind in
            let items = TuningCatalog.all.filter { $0.instrument == kind }
            return items.isEmpty ? nil : (kind, items)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PitchTheme.appBackground(scheme).ignoresSafeArea()
                List {
                    if !customTunings.isEmpty {
                        Section("My tunings") {
                            ForEach(customTunings) { custom in
                                tuningRow(custom.asTuning)
                            }
                            .onDelete(perform: deleteCustom)
                        }
                    }
                    ForEach(grouped, id: \.0) { kind, items in
                        Section(kind.rawValue) {
                            ForEach(items) { tuning in
                                tuningRow(tuning)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Tunings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if isPro { showBuilder = true } else { showPaywall = true }
                    } label: {
                        Label("New tuning", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showBuilder) { CustomTuningBuilder() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func tuningRow(_ tuning: Tuning) -> some View {
        let selected = tuning.id == activeTuningID
        return Button {
            activeTuningID = tuning.id
            Haptics.tap(haptics)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: tuning.instrument.systemImage)
                    .font(.title3)
                    .foregroundStyle(PitchTheme.indigo)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tuning.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PitchTheme.primaryText(scheme))
                    Text(tuning.isChromatic ? "All notes" : displayTargets(tuning.targets))
                        .font(PitchTheme.mono(12))
                        .foregroundStyle(PitchTheme.secondaryText(scheme))
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(PitchTheme.indigo)
                }
            }
        }
        .listRowBackground(PitchTheme.cardSurface(scheme))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(tuning.name)
        .accessibilityValue(selected ? "Selected" : "")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func displayTargets(_ targets: [String]) -> String {
        targets.compactMap { token -> String? in
            guard let p = NoteMath.parseTarget(token) else { return token }
            return "\(p.name)\(p.octave)"
        }.joined(separator: " ")
    }

    private func deleteCustom(_ offsets: IndexSet) {
        for index in offsets {
            guard let item = customTunings[safe: index] else { continue }
            // If the deleted tuning was active, fall back to the default.
            if "custom-\(item.uuid)" == activeTuningID {
                activeTuningID = TuningCatalog.defaultID
            }
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}
