import SwiftUI

/// One tracker's logging control for a given day. The control adapts to the tracker's scaleType:
/// a slider (severity), a stepper (count), a toggle (yes/no), or a numeric field. A row reports its
/// value through `draft` bindings owned by the parent so saving is one pass.
struct LogRowView: View {
    let tracker: Tracker
    let scale10: Bool
    @Binding var draft: LogDraft
    var onChange: () -> Void

    private var severityMax: Double { tracker.severityMax(scale10: scale10) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                TrackerIcon(symbol: tracker.symbolName, color: tracker.color)
                VStack(alignment: .leading, spacing: 1) {
                    Text(tracker.name)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(tracker.kind.title + (tracker.unit.map { " · \($0)" } ?? ""))
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer(minLength: 0)
                if draft.isSet {
                    Text(valueLabel)
                        .font(Theme.mono(15, .semibold))
                        .foregroundStyle(tracker.color)
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: "circle.dashed")
                        .foregroundStyle(Theme.inkFaint)
                        .accessibilityHidden(true)
                }
            }

            control
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(draft.isSet ? tracker.color.opacity(0.4) : Theme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var control: some View {
        switch tracker.scaleType {
        case .severity:
            VStack(spacing: 2) {
                Slider(value: Binding(
                    get: { draft.isSet ? draft.value : 0 },
                    set: { draft.value = $0.rounded(); draft.isSet = true; onChange() }),
                       in: 0...severityMax, step: 1)
                .tint(tracker.color)
                .accessibilityLabel("\(tracker.name) severity")
                .accessibilityValue(draft.isSet ? "\(Int(draft.value)) of \(Int(severityMax))" : "Not set")
                HStack {
                    Text("None").font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
                    Spacer()
                    Text("Worst").font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
                }
            }

        case .yesNo:
            Toggle(isOn: Binding(
                get: { draft.isSet && draft.value >= 0.5 },
                set: { draft.value = $0 ? 1 : 0; draft.isSet = true; onChange() })) {
                Text(draft.isSet && draft.value >= 0.5 ? "Yes" : "No")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
            .tint(tracker.color)
            .accessibilityLabel("\(tracker.name)")
            .accessibilityValue(draft.isSet && draft.value >= 0.5 ? "Yes" : "No")

        case .count:
            Stepper(value: Binding(
                get: { draft.isSet ? draft.value : 0 },
                set: { draft.value = max(0, $0); draft.isSet = true; onChange() }),
                    in: 0...999, step: 1) {
                Text("\(Int(draft.isSet ? draft.value : 0)) \(tracker.unit ?? "")")
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.ink)
            }
            .accessibilityLabel("\(tracker.name) count")
            .accessibilityValue("\(Int(draft.isSet ? draft.value : 0))")

        case .numeric:
            HStack(spacing: 8) {
                TextField("Value", text: Binding(
                    get: { draft.text },
                    set: { newValue in
                        draft.text = newValue
                        if let n = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                            draft.value = n
                            draft.isSet = true
                        } else if newValue.isEmpty {
                            draft.isSet = false
                        }
                        onChange()
                    }))
                .keyboardType(.decimalPad)
                .font(Theme.rounded(16))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: Theme.cornerSmall).fill(Theme.surfaceAlt))
                if let unit = tracker.unit, !unit.isEmpty {
                    Text(unit).font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                }
            }
            .accessibilityLabel("\(tracker.name) value")
        }
    }

    private var valueLabel: String {
        tracker.displayValue(draft.value, scale10: scale10)
    }
}

/// An in-flight value for one tracker on the day being logged.
struct LogDraft {
    var value: Double = 0
    var isSet: Bool = false
    var text: String = ""

    /// Build from an existing entry (so editing a day pre-fills).
    static func from(value: Double?) -> LogDraft {
        guard let value else { return LogDraft() }
        return LogDraft(value: value, isSet: true,
                        text: value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value))
    }
}
