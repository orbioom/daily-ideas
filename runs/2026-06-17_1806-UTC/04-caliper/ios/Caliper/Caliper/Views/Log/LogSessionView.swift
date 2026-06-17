import SwiftUI
import SwiftData

struct LogSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var proStore: ProStore

    @Query(sort: \MeasurementSite.sortOrder) private var sites: [MeasurementSite]

    @State private var date = Date()
    /// Raw text fields keyed by site key.
    @State private var inputs: [String: String] = [:]
    @State private var fieldErrors: [String: String] = [:]
    @State private var toast: String?
    @State private var showPaywall = false

    private var availableSites: [MeasurementSite] {
        sites.filter { proStore.isPro || ProGate.freeSiteKeys.contains($0.key) }
    }

    private var lockedCount: Int {
        sites.count - availableSites.count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Session date", selection: $date, in: ...Date(), displayedComponents: .date)
                }

                navySection

                Section {
                    ForEach(availableSites) { site in
                        fieldRow(for: site)
                    }
                } header: {
                    Text("Measurements")
                } footer: {
                    Text("Fill in any subset. Empty fields are skipped.")
                        .foregroundStyle(Theme.inkSoft)
                }

                if lockedCount > 0 {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("\(lockedCount) more sites in Pro", systemImage: "crown.fill")
                                .foregroundStyle(Theme.ink)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Log session")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveSession() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .toast(message: $toast)
        }
    }

    // MARK: Field row

    @ViewBuilder
    private func fieldRow(for site: MeasurementSite) -> some View {
        let unit = Units.unitLabel(kind: site.unitKind, system: settings.unitSystem)
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: SiteCatalog.symbol(for: site.key))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                Text(site.name)
                    .font(Theme.rounded(16, .medium))
                    .foregroundStyle(Theme.ink)
                Spacer()
                TextField("—", text: binding(for: site.key))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 90)
                    .accessibilityLabel("\(site.name) in \(unit)")
                Text(unit)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(width: 28, alignment: .leading)
            }
            if let err = fieldErrors[site.key] {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(Theme.bad)
                    .padding(.leading, 32)
            }
        }
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { inputs[key] ?? "" },
            set: { inputs[key] = $0 }
        )
    }

    // MARK: Navy auto-compute

    private var navyComputed: Double? {
        guard let neck = canonicalInput(for: "neck"),
              let waist = canonicalInput(for: "waist") else { return nil }
        let hip = canonicalInput(for: "hips")
        return BodyMath.navyBodyFat(
            sex: settings.biologicalSex,
            neckCm: neck,
            waistCm: waist,
            hipCm: hip,
            heightCm: settings.heightCm
        )
    }

    private var navySection: some View {
        Section {
            if let bf = navyComputed {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Navy body-fat estimate")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("\(Units.number(bf, digits: 1)) % from neck/waist\(settings.biologicalSex == .female ? "/hips" : "")/height")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Button("Use") {
                        inputs["bodyfat"] = Units.number(bf, digits: 1)
                        fieldErrors["bodyfat"] = nil
                        Haptics.selection(enabled: settings.hapticsEnabled)
                    }
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Theme.accent, in: Capsule())
                    .accessibilityHint("Copies the computed body-fat percentage into the Body fat field")
                }
            } else {
                Label("Need neck, waist\(settings.biologicalSex == .female ? ", hips" : "") and height to auto-compute body-fat.",
                      systemImage: "info.circle")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
            }
        } header: {
            Text("Auto body-fat (US Navy)")
        }
    }

    /// Returns the canonical value for a key from current text input, if parseable & positive.
    private func canonicalInput(for key: String) -> Double? {
        guard let raw = inputs[key], !raw.isEmpty,
              let site = sites.first(where: { $0.key == key }) else { return nil }
        let normalized = raw.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard let display = Double(normalized), display > 0 else { return nil }
        return Units.canonicalValue(display: display, kind: site.unitKind, system: settings.unitSystem)
    }

    // MARK: Save

    private func saveSession() {
        fieldErrors = [:]
        var toInsert: [(String, Double)] = []
        var hadError = false

        for site in availableSites {
            guard let raw = inputs[site.key], !raw.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            let normalized = raw.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
            guard let display = Double(normalized) else {
                fieldErrors[site.key] = "Not a number"
                hadError = true
                continue
            }
            guard display > 0 else {
                fieldErrors[site.key] = "Must be positive"
                hadError = true
                continue
            }
            let range = Units.plausibleRange(kind: site.unitKind, system: settings.unitSystem)
            guard range.contains(display) else {
                fieldErrors[site.key] = "Out of range"
                hadError = true
                continue
            }
            let canonical = Units.canonicalValue(display: display, kind: site.unitKind, system: settings.unitSystem)
            toInsert.append((site.key, canonical))
        }

        if hadError {
            Haptics.warning(enabled: settings.hapticsEnabled)
            toast = "Fix the highlighted fields"
            return
        }

        guard !toInsert.isEmpty else {
            Haptics.warning(enabled: settings.hapticsEnabled)
            toast = "Enter at least one value"
            return
        }

        for (key, value) in toInsert {
            modelContext.insert(MeasurementEntry(siteKey: key, valueCanonical: value, date: date))
        }
        try? modelContext.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        toast = "Saved \(toInsert.count) measurement\(toInsert.count == 1 ? "" : "s")"
        inputs = [:]
    }
}
