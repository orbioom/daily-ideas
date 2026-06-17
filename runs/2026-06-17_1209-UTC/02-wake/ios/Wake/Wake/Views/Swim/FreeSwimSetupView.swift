import SwiftUI

/// Quick setup for a free swim: choose stroke and a target distance to swim as one rep.
/// You can stop and save whenever you like.
struct FreeSwimSetupView: View {
    let poolLength: PoolLength
    let onStart: ([RunnerRep]) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage(PrefKey.defaultStrokeRaw) private var defaultStrokeRaw = Stroke.freestyle.rawValue
    @AppStorage(PrefKey.unitsRaw) private var unitsRaw = DistanceUnit.meters.rawValue

    @State private var stroke: Stroke = .freestyle
    @State private var distanceText = "1000"

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitsRaw) ?? .meters }

    var body: some View {
        NavigationStack {
            Form {
                Section("Stroke") {
                    Picker("Stroke", selection: $stroke) {
                        ForEach(Stroke.allCases) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("Target distance (\(unit.shortUnit))") {
                    TextField("Distance", text: $distanceText)
                        .keyboardType(.numberPad)
                    Text("Swim continuously, then stop and save. You can record laps as a single split.")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .navigationTitle("Free swim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Start") { start() }
                        .fontWeight(.semibold)
                        .disabled(parsedMeters <= 0)
                }
            }
            .onAppear { stroke = Stroke.from(defaultStrokeRaw) }
        }
    }

    private var parsedMeters: Double {
        let value = Double(distanceText.trimmingCharacters(in: .whitespaces)) ?? 0
        return unit.meters(fromValue: max(0, value))
    }

    private func start() {
        let meters = parsedMeters
        guard meters > 0 else { return }
        let rep = RunnerRep(setIndex: 0,
                            repIndex: 0,
                            repsInSet: 1,
                            stroke: stroke,
                            distanceMeters: meters,
                            sendOffSeconds: 0,
                            restSeconds: 0,
                            effort: .moderate,
                            note: "Free swim")
        onStart([rep])
        dismiss()
    }
}
