import SwiftUI
import SwiftData

/// New cook flow: pick protein → cut (auto-fills target/ambient/wood), set weight/method, start.
struct NewCookView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPro") private var isPro = false

    @Query private var allCooks: [Cook]

    @State private var name = ""
    @State private var protein: Protein = .beef
    @State private var cut: String = ""
    @State private var method: CookMethod = .smoke
    @State private var weightLb: Double = 4
    @State private var woodType: String = ""
    @State private var rubName: String = ""
    @State private var startNow = true
    @State private var paywallReason: PaywallReason?

    @Query(sort: \Rub.name) private var rubs: [Rub]

    private var cutsForProtein: [String] { DonenessGuide.cuts(for: protein) }

    private var guideEntry: GuideEntry? {
        DonenessGuide.entry(protein: protein, cut: cut)
    }

    private var activeCookCount: Int {
        allCooks.filter { $0.status.isActive }.count
    }

    private var wouldExceedFreeLimit: Bool {
        startNow && !isPro && activeCookCount >= Pro.freeActiveCookLimit
    }

    private var canSave: Bool {
        !cut.isEmpty && weightLb > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Sunday Brisket", text: $name)
                }

                Section("Protein & cut") {
                    Picker("Protein", selection: $protein) {
                        ForEach(Protein.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Cut", selection: $cut) {
                        Text("Choose a cut").tag("")
                        ForEach(cutsForProtein, id: \.self) { Text($0).tag($0) }
                    }
                }

                if let entry = guideEntry {
                    Section("From the guide") {
                        labeledRow("Target temp", settings.temp(entry.defaultTargetC))
                        labeledRow("Smoker / grill temp", settings.temp(entry.smokerTempC))
                        labeledRow("Suggested wood", entry.woodPairing)
                        labeledRow("Rest", "\(entry.restMinutes) min")
                    }
                }

                Section("Method & weight") {
                    Picker("Method", selection: $method) {
                        ForEach(CookMethod.allCases) { Text($0.label).tag($0) }
                    }
                    HStack {
                        Text("Weight")
                        Spacer()
                        Text(String(format: settings.usePounds ? "%.1f lb" : "%.2f kg",
                                    settings.usePounds ? weightLb : Units.lbToKg(weightLb)))
                            .foregroundStyle(Theme.inkSoft)
                            .monospacedDigit()
                    }
                    Slider(value: $weightLb, in: 0.25...30, step: 0.25)
                        .tint(Theme.accent)
                        .accessibilityValue(String(format: "%.1f pounds", weightLb))
                }

                Section("Wood & rub (optional)") {
                    Picker("Wood", selection: $woodType) {
                        Text("None").tag("")
                        ForEach(WoodTypes.names, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Rub", selection: $rubName) {
                        Text("None").tag("")
                        ForEach(rubs) { Text($0.name).tag($0.name) }
                    }
                }

                Section {
                    Toggle("Start cooking now", isOn: $startNow)
                    if wouldExceedFreeLimit {
                        Button {
                            paywallReason = .secondCook
                        } label: {
                            Label("Free tier allows one live cook — get Pro", systemImage: "lock.fill")
                                .font(Theme.rounded(13, .semibold))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                } footer: {
                    Text(startNow ? "The timer starts immediately." : "Saved as planned — start it later from the Cooks list.")
                }
            }
            .navigationTitle("New Cook")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!canSave || wouldExceedFreeLimit)
                        .fontWeight(.semibold)
                }
            }
            .onChange(of: protein) { _, _ in
                // Reset the cut when protein changes so the picker stays valid.
                cut = cutsForProtein.first ?? ""
                applyGuideDefaults()
            }
            .onChange(of: cut) { _, _ in applyGuideDefaults() }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .onAppear {
                method = settings.defaultMethod
                if cut.isEmpty { cut = cutsForProtein.first ?? "" }
            }
        }
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value).foregroundStyle(Theme.ink).fontWeight(.medium)
        }
    }

    /// Auto-fill wood suggestion from the guide when the cut changes (only if user hasn't set one).
    private func applyGuideDefaults() {
        guard let entry = guideEntry else { return }
        if woodType.isEmpty {
            // Match the first guide-suggested wood to a known wood name if possible.
            if let match = WoodTypes.names.first(where: { entry.woodPairing.localizedCaseInsensitiveContains($0) }) {
                woodType = match
            }
        }
    }

    private func save() {
        guard canSave, !wouldExceedFreeLimit else { return }
        let entry = guideEntry
        let kg = Units.lbToKg(weightLb)
        let target = entry?.defaultTargetC ?? 71
        let ambient = entry?.smokerTempC ?? (method == .smoke ? 121 : 218)
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let finalName = trimmedName.isEmpty ? cut : trimmedName

        let cook = Cook(name: finalName,
                        protein: protein,
                        cut: cut,
                        weightKg: kg,
                        method: method,
                        targetInternalTempC: target,
                        ambientTempC: ambient,
                        woodType: woodType.isEmpty ? nil : woodType,
                        rubName: rubName.isEmpty ? nil : rubName,
                        status: startNow ? .cooking : .planned,
                        startDate: startNow ? Date() : nil)
        context.insert(cook)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
