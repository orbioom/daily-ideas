import SwiftUI

struct ConvertView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var showSettings = false
    @State private var mode: Mode = .recipe

    enum Mode: String, CaseIterable, Identifiable {
        case recipe = "Recipe", units = "Units", doneness = "Doneness"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .onChange(of: mode) { _, _ in
                        Haptics.selection(enabled: settings.hapticsEnabled)
                    }

                    ScrollView {
                        Group {
                            switch mode {
                            case .recipe: OvenConverterCard()
                            case .units: UnitConverterCard()
                            case .doneness: DonenessGuideList()
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Convert")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }
}
