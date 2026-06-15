import SwiftUI
import SwiftData

/// The full daily check-in editor, reused by Today and the Calendar day detail.
/// Operates directly on a `@Bindable` DayLog already inserted into the context.
struct DayLogEditor: View {
    @Bindable var log: DayLog
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext

    /// Called after a meaningful change so the host can save + show confirmation.
    var onChange: () -> Void = {}

    @State private var expandedAll = false

    private var showFull: Bool { expandedAll || settings.defaultSymptomsShown }

    var body: some View {
        VStack(spacing: 18) {
            hotFlashCard
            quickTogglesCard
            ratingsCard
            if settings.trackCycle { flowCard }
            symptomsCard
            treatmentsCard
            notesCard
        }
        .onAppear { expandedAll = settings.defaultSymptomsShown }
    }

    // MARK: - Hot flashes

    private var hotFlashCard: some View {
        VStack(spacing: 14) {
            SectionHeader(title: "Hot flashes today", systemImage: "thermometer.sun.fill")
            HStack(spacing: 20) {
                stepperButton(symbol: "minus") {
                    if log.hotFlashCount > 0 {
                        log.hotFlashCount -= 1
                        Haptics.selection(enabled: settings.hapticsEnabled)
                        onChange()
                    }
                }
                .disabled(log.hotFlashCount == 0)
                .opacity(log.hotFlashCount == 0 ? 0.4 : 1)

                VStack(spacing: 2) {
                    Text("\(log.hotFlashCount)")
                        .font(Theme.rounded(46, .bold))
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText())
                        .frame(minWidth: 70)
                    Text(log.hotFlashCount == 1 ? "flash" : "flashes")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Hot flashes")
                .accessibilityValue("\(log.hotFlashCount)")

                stepperButton(symbol: "plus") {
                    log.hotFlashCount = min(99, log.hotFlashCount + 1)
                    Haptics.selection(enabled: settings.hapticsEnabled)
                    onChange()
                }
            }
        }
        .padding(18)
        .cardSurface()
    }

    private func stepperButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Theme.accent))
        }
        .buttonStyle(PressableScale())
        .accessibilityLabel(symbol == "plus" ? "Add a hot flash" : "Remove a hot flash")
    }

    // MARK: - Quick toggles

    private var quickTogglesCard: some View {
        Toggle(isOn: Binding(
            get: { log.nightSweats },
            set: { log.nightSweats = $0; Haptics.tap(enabled: settings.hapticsEnabled); onChange() }
        )) {
            Label {
                Text("Night sweats")
                    .font(Theme.rounded(16, .medium))
                    .foregroundStyle(Theme.ink)
            } icon: {
                Image(systemName: "moon.stars.fill").foregroundStyle(Theme.dusk)
            }
        }
        .tint(Theme.accent)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .cardSurface()
    }

    // MARK: - Ratings

    private var ratingsCard: some View {
        VStack(spacing: 18) {
            RatingSelector(title: "Mood", symbol: "face.smiling",
                           value: ratingBinding(\.mood),
                           lowLabel: "Low", highLabel: "Bright",
                           hapticsEnabled: settings.hapticsEnabled)
            RatingSelector(title: "Sleep quality", symbol: "bed.double.fill",
                           value: ratingBinding(\.sleepQuality),
                           lowLabel: "Poor", highLabel: "Restful",
                           hapticsEnabled: settings.hapticsEnabled)
            RatingSelector(title: "Energy", symbol: "bolt.fill",
                           value: ratingBinding(\.energy),
                           lowLabel: "Drained", highLabel: "Vital",
                           hapticsEnabled: settings.hapticsEnabled)
        }
        .padding(18)
        .cardSurface()
    }

    private func ratingBinding(_ keyPath: ReferenceWritableKeyPath<DayLog, Int>) -> Binding<Int> {
        Binding(
            get: { log[keyPath: keyPath] },
            set: { log[keyPath: keyPath] = DayLog.clampRating($0); onChange() }
        )
    }

    // MARK: - Flow

    private var flowCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Flow", systemImage: "drop.fill")
            HStack(spacing: 8) {
                ForEach(Flow.allCases) { flow in
                    Button {
                        log.flow = flow
                        Haptics.selection(enabled: settings.hapticsEnabled)
                        onChange()
                    } label: {
                        Text(flow.rawValue)
                            .font(Theme.rounded(13, .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .foregroundStyle(log.flow == flow ? .white : Theme.inkSoft)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                                    .fill(log.flow == flow ? Theme.bad : Theme.surfaceAlt)
                            )
                    }
                    .buttonStyle(PressableScale())
                    .accessibilityLabel("Flow \(flow.rawValue)")
                    .accessibilityAddTraits(log.flow == flow ? .isSelected : [])
                }
            }
        }
        .padding(18)
        .cardSurface()
    }

    // MARK: - Symptoms

    private var symptomsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "Symptoms", systemImage: "list.bullet.clipboard")
                if !settings.defaultSymptomsShown {
                    Button(showFull ? "Less" : "More") {
                        withAnimation(.easeInOut(duration: 0.2)) { expandedAll.toggle() }
                    }
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.accent)
                }
            }
            ForEach(SymptomDomain.allCases) { domain in
                let symptoms = visibleSymptoms(in: domain)
                if !symptoms.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(domain.rawValue.uppercased())
                            .font(Theme.rounded(11, .bold))
                            .foregroundStyle(Theme.inkFaint)
                        ForEach(symptoms) { symptom in
                            symptomRow(symptom)
                        }
                    }
                }
            }
        }
        .padding(18)
        .cardSurface()
    }

    private func visibleSymptoms(in domain: SymptomDomain) -> [Symptom] {
        let all = SymptomCatalog.symptoms(in: domain)
        if showFull { return all }
        // Compact: show common ones, plus any already given a severity so they stay editable.
        return all.filter { SymptomCatalog.commonKeys.contains($0.key) || log.severity(for: $0.key) > 0 }
    }

    private func symptomRow(_ symptom: Symptom) -> some View {
        let current = log.severity(for: symptom.key)
        return VStack(alignment: .leading, spacing: 6) {
            Text(symptom.name)
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 6) {
                ForEach(Severity.allCases) { sev in
                    Button {
                        setSeverity(symptom.key, to: sev.rawValue, current: current)
                    } label: {
                        Text(sev.label)
                            .font(Theme.rounded(12, .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .foregroundStyle(current == sev.rawValue ? .white : Theme.inkSoft)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(current == sev.rawValue ? severityColor(sev) : Theme.surfaceAlt)
                            )
                    }
                    .buttonStyle(PressableScale())
                    .accessibilityLabel("\(symptom.name) \(sev.label)")
                    .accessibilityAddTraits(current == sev.rawValue ? .isSelected : [])
                }
            }
        }
    }

    private func severityColor(_ sev: Severity) -> Color {
        switch sev {
        case .none: return Theme.inkFaint
        case .mild: return Theme.good
        case .moderate: return Theme.warn
        case .severe: return Theme.bad
        }
    }

    private func setSeverity(_ key: String, to value: Int, current: Int) {
        var dict = log.symptoms
        if value <= 0 {
            dict.removeValue(forKey: key)
        } else {
            dict[key] = value
        }
        log.symptoms = dict
        Haptics.selection(enabled: settings.hapticsEnabled)
        onChange()
    }

    // MARK: - Treatments

    private var treatmentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Treatments & supplements", systemImage: "pills.fill")
            FlowChips(items: TreatmentCatalog.all,
                      isSelected: { log.treatments.contains($0) },
                      toggle: { toggleTreatment($0) })
        }
        .padding(18)
        .cardSurface()
    }

    private func toggleTreatment(_ name: String) {
        var list = log.treatments
        if let idx = list.firstIndex(of: name) {
            list.remove(at: idx)
        } else {
            list.append(name)
        }
        log.treatments = list
        Haptics.selection(enabled: settings.hapticsEnabled)
        onChange()
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Notes", systemImage: "square.and.pencil")
            TextField("Anything worth remembering today…",
                      text: Binding(get: { log.notes }, set: { log.notes = $0; onChange() }),
                      axis: .vertical)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.ink)
                .lineLimit(2...6)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                        .fill(Theme.surfaceAlt)
                )
                .accessibilityLabel("Notes")
        }
        .padding(18)
        .cardSurface()
    }
}

/// A simple wrapping chip layout for the treatment list.
struct FlowChips: View {
    let items: [String]
    let isSelected: (String) -> Bool
    let toggle: (String) -> Void

    var body: some View {
        // A lightweight wrap using a fixed-column grid keeps layout deterministic on iOS 17.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                let selected = isSelected(item)
                Button {
                    toggle(item)
                } label: {
                    Text(item)
                        .font(Theme.rounded(13, .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .foregroundStyle(selected ? .white : Theme.inkSoft)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selected ? Theme.accent : Theme.surfaceAlt)
                        )
                }
                .buttonStyle(PressableScale())
                .accessibilityLabel(item)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}
