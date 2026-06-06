import SwiftUI
import SwiftData

/// Create or edit a dive.
struct DiveEditView: View {
    @Bindable var dive: Dive
    var isNew: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \DiveSite.name) private var sites: [DiveSite]
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.metric.rawValue
    @AppStorage("defaultO2") private var defaultO2 = 21

    @State private var maxDepthText = ""
    @State private var avgDepthText = ""
    @State private var durationText = ""
    @State private var tempText = ""
    @State private var isNitrox = false
    @State private var o2 = 21
    @State private var startBar = 200
    @State private var endBar = 50
    @State private var tankText = "12"
    @State private var siteMode = 0     // 0 existing, 1 new
    @State private var selectedSite: DiveSite?
    @State private var newSiteName = ""
    @State private var newSiteLocation = ""

    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .metric }
    private var canSave: Bool {
        (Double(maxDepthText.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
            && (Int(durationText) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                siteSection
                Section("Dive") {
                    DatePicker("Date", selection: $dive.date)
                    field("Max depth (\(unit.depthUnit))", $maxDepthText)
                    field("Avg depth (\(unit.depthUnit), optional)", $avgDepthText)
                    HStack {
                        Text("Duration (min)"); Spacer()
                        TextField("0", text: $durationText).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).frame(width: 80).font(Brand.mono(16))
                    }
                    field("Water temp (\(unit.tempUnit))", $tempText)
                    Picker("Type", selection: Binding(get: { dive.type }, set: { dive.type = $0 })) {
                        ForEach(DiveType.allCases) { Text($0.label).tag($0) }
                    }
                }
                Section("Gas & cylinder") {
                    Toggle("Nitrox", isOn: $isNitrox.animation())
                    if isNitrox {
                        Stepper(value: $o2, in: 22...40) {
                            HStack { Text("Oxygen %"); Spacer(); Text("\(o2)%").font(Brand.mono(15)).foregroundStyle(Brand.text2) }
                        }
                    }
                    Stepper(value: $startBar, in: 0...350, step: 5) {
                        HStack { Text("Start pressure"); Spacer(); Text("\(startBar) bar").font(Brand.mono(15)).foregroundStyle(Brand.text2) }
                    }
                    Stepper(value: $endBar, in: 0...350, step: 5) {
                        HStack { Text("End pressure"); Spacer(); Text("\(endBar) bar").font(Brand.mono(15)).foregroundStyle(Brand.text2) }
                    }
                    HStack {
                        Text("Tank (litres)"); Spacer()
                        TextField("12", text: $tankText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 80).font(Brand.mono(16))
                    }
                }
                Section("Notes") {
                    TextField("Buddy", text: $dive.buddy)
                    TextField("Visibility", text: $dive.visibility)
                    HStack { Text("Rating"); Spacer(); StarRating(rating: $dive.rating, editable: true) }
                    TextField("Notes", text: $dive.notes, axis: .vertical).lineLimit(2...6)
                }
                if let mod = modWarning { Section { Text(mod).foregroundStyle(Brand.danger).font(.subheadline) } }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(isNew ? "Log Dive" : "Edit Dive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { cancel() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    @ViewBuilder private var siteSection: some View {
        Section("Site") {
            if !sites.isEmpty {
                Picker("Source", selection: $siteMode) { Text("Existing").tag(0); Text("New").tag(1) }
                    .pickerStyle(.segmented)
            }
            if siteMode == 0 && !sites.isEmpty {
                Picker("Site", selection: $selectedSite) {
                    Text("Choose…").tag(Optional<DiveSite>.none)
                    ForEach(sites) { Text($0.name).tag(Optional($0)) }
                }
            } else {
                TextField("Site name", text: $newSiteName)
                TextField("Location", text: $newSiteLocation)
            }
        }
    }

    private var modWarning: String? {
        guard let depth = Double(maxDepthText.replacingOccurrences(of: ",", with: ".")), depth > 0 else { return nil }
        let depthM = unit.depthToM(depth)
        let o2val = isNitrox ? o2 : 21
        let ppo2 = DiveMath.ppO2(oxygenPercent: o2val, atDepth: depthM)
        if ppo2 > 1.4 {
            return String(format: "Heads up: ppO₂ at this depth is %.2f (over the 1.4 recreational limit) on %@.", ppo2, BreathingGas(oxygenPercent: o2val).label)
        }
        return nil
    }

    private func field(_ label: String, _ binding: Binding<String>) -> some View {
        HStack {
            Text(label); Spacer()
            TextField("0", text: binding).keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing).frame(width: 90).font(Brand.mono(16))
        }
    }

    private func load() {
        if isNew {
            o2 = defaultO2; isNitrox = defaultO2 != 21
            selectedSite = sites.first
            if sites.isEmpty { siteMode = 1 }
            return
        }
        selectedSite = dive.site
        maxDepthText = dive.maxDepthM > 0 ? trim(unit.depthOut(dive.maxDepthM)) : ""
        avgDepthText = dive.avgDepthM > 0 ? trim(unit.depthOut(dive.avgDepthM)) : ""
        durationText = dive.durationMin > 0 ? String(dive.durationMin) : ""
        tempText = trim(unit.tempOut(dive.waterTempC))
        o2 = dive.oxygenPercent; isNitrox = dive.oxygenPercent != 21
        startBar = dive.startPressureBar; endBar = dive.endPressureBar
        tankText = trim(dive.tankLitres)
    }

    private func save() {
        // resolve site
        if siteMode == 1 || sites.isEmpty {
            let trimmed = newSiteName.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                let s = DiveSite(name: trimmed, location: newSiteLocation.trimmingCharacters(in: .whitespaces))
                context.insert(s)
                dive.site = s
            }
        } else {
            dive.site = selectedSite
        }
        dive.maxDepthM = unit.depthToM(parse(maxDepthText))
        dive.avgDepthM = unit.depthToM(parse(avgDepthText))
        dive.durationMin = max(0, Int(durationText) ?? 0)
        dive.waterTempC = tempText.isEmpty ? 0 : unit.tempToC(parse(tempText))
        dive.oxygenPercent = isNitrox ? o2 : 21
        dive.startPressureBar = startBar
        dive.endPressureBar = min(endBar, startBar)
        dive.tankLitres = max(0, parse(tankText))
        try? context.save(); Haptics.success(); dismiss()
    }
    private func cancel() { if isNew { context.delete(dive) }; dismiss() }
    private func parse(_ s: String) -> Double { max(0, Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0) }
    private func trim(_ d: Double) -> String { d == d.rounded() ? String(Int(d)) : String(format: "%.1f", d) }
}
