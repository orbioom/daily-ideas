import SwiftUI
import SwiftData

/// Quick sheet to log an internal temperature reading for a cook.
struct LogTempSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @Bindable var cook: Cook

    /// Entered in the user's display unit; converted to Celsius on save.
    @State private var displayTemp: Double
    @State private var note = ""

    init(cook: Cook) {
        self.cook = cook
        // Seed near the latest reading or a sensible mid value.
        let latestC = cook.latestInternalTempC ?? 40
        let useF = UserDefaults.standard.object(forKey: "useFahrenheit") as? Bool ?? true
        _displayTemp = State(initialValue: useF ? Units.cToF(latestC) : latestC)
    }

    private var range: ClosedRange<Double> {
        settings.useFahrenheit ? 32...250 : 0...121
    }

    private var step: Double { settings.useFahrenheit ? 1 : 0.5 }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("\(Int(displayTemp.rounded()))\(settings.tempUnitSuffix)")
                            .font(Theme.numeral(56, .heavy))
                            .foregroundStyle(Theme.accent)
                            .monospacedDigit()
                        Text("Internal temperature")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .padding(.top, 12)

                    Slider(value: $displayTemp, in: range, step: step)
                        .tint(Theme.accent)
                        .accessibilityValue("\(Int(displayTemp.rounded())) degrees")

                    HStack {
                        Text("Target")
                            .foregroundStyle(Theme.inkSoft)
                        Spacer()
                        Text(settings.temp(cook.targetInternalTempC))
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.ink)
                    }
                    .font(Theme.rounded(15))
                    .padding(.horizontal, 4)

                    TextField("Note (optional)", text: $note)
                        .textFieldStyle(.roundedBorder)

                    PrimaryButton(title: "Log reading", systemImage: "plus.circle.fill") {
                        save()
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Log temp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let celsius = settings.useFahrenheit ? Units.fToC(displayTemp) : displayTemp
        let log = TempLog(time: Date(), internalTempC: celsius, note: note.trimmingCharacters(in: .whitespaces))
        log.cook = cook
        cook.tempLogs.append(log)
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
        dismiss()
    }
}
