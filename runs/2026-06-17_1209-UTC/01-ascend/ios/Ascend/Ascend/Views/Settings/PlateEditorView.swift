import SwiftUI

/// Edit the set of plates available in the gym (per side, in the display unit).
struct PlateEditorView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var newPlateText = ""

    private var unit: WeightUnit { settings.unit }

    var body: some View {
        Form {
            Section {
                ForEach(settings.plateSetKg, id: \.self) { kg in
                    HStack {
                        Text(Units.formatWeight(kg, unit: unit))
                            .font(Theme.rounded(16, .semibold))
                        Spacer()
                        Button {
                            settings.removePlate(kg)
                            Haptics.tap(settings.hapticsEnabled)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(Theme.bad)
                        }
                        .accessibilityLabel("Remove \(Units.formatWeight(kg, unit: unit)) plate")
                    }
                }
            } header: {
                Text("Available plates (\(unit.label))")
            } footer: {
                Text("Each plate is assumed to come in pairs — one per side of the bar.")
            }

            Section("Add a plate") {
                HStack {
                    TextField("e.g. 1.25", text: $newPlateText)
                        .keyboardType(.decimalPad)
                    Button("Add") {
                        if let v = Double(newPlateText.replacingOccurrences(of: ",", with: ".")), v > 0 {
                            settings.addPlate(displayValue: v)
                            newPlateText = ""
                            Haptics.success(settings.hapticsEnabled)
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.accent)
                }
            }

            Section {
                Button("Reset to standard plates") {
                    settings.resetPlates()
                    Haptics.tap(settings.hapticsEnabled)
                }
                .foregroundStyle(Theme.inkSoft)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Plates")
        .navigationBarTitleDisplayMode(.inline)
    }
}
