import SwiftUI
import SwiftData

struct FiringEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("cone.celsius") private var celsius = false
    let existing: Firing?

    @State private var name = ""
    @State private var date = Date()
    @State private var kind = "Glaze"
    @State private var targetCone = "6"
    @State private var atmosphere = "Oxidation"
    @State private var fastRamp = false
    @State private var startTempF = 70.0
    @State private var result = "Planned"
    @State private var resultNotes = ""
    @State private var segments: [SegDraft] = []

    struct SegDraft: Identifiable { let id = UUID(); var rate: Double; var target: Double; var hold: Double }

    private let kinds = ["Bisque", "Glaze"]
    private let atmospheres = ["Oxidation", "Reduction", "Neutral"]
    private let results = ["Planned", "Success", "Issues"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    basicsCard
                    segmentsCard
                    resultCard
                }
                .padding()
            }
            .navigationTitle(existing == nil ? "New Firing" : "Edit Firing")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var basicsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Firing name", text: $name).font(.headline).foregroundStyle(Brand.text)
            Divider().overlay(Brand.hairline)
            DatePicker("Date", selection: $date, displayedComponents: .date).tint(Brand.text).foregroundStyle(Brand.text2)
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Type").foregroundStyle(Brand.text2); Spacer()
                Picker("Type", selection: $kind) { ForEach(kinds, id: \.self) { Text($0).tag($0) } }.tint(Brand.text)
            }
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Target cone").foregroundStyle(Brand.text2); Spacer()
                Picker("Cone", selection: $targetCone) { ForEach(ConeMath.coneNames, id: \.self) { Text("△\($0)").tag($0) } }.tint(Brand.text)
            }
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Atmosphere").foregroundStyle(Brand.text2); Spacer()
                Picker("Atmosphere", selection: $atmosphere) { ForEach(atmospheres, id: \.self) { Text($0).tag($0) } }.tint(Brand.text)
            }
            Divider().overlay(Brand.hairline)
            Toggle("Fast final ramp (270°F/hr)", isOn: $fastRamp).tint(Brand.live).foregroundStyle(Brand.text)
        }
        .font(.subheadline).glassCard()
    }

    private var segmentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Ramp segments")
                Spacer()
                Button {
                    segments.append(SegDraft(rate: 108, target: 2000, hold: 0)); Haptics.tap()
                } label: { Image(systemName: "plus.circle") }.accessibilityLabel("Add segment")
            }
            if segments.isEmpty {
                Text("Add ramp steps. Use rate 0 for as-fast-as-possible.").font(.caption).foregroundStyle(Brand.text3)
            }
            ForEach($segments) { $seg in
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        field("Rate °/hr") {
                            TextField("108", value: $seg.rate, format: .number).keyboardType(.numberPad)
                        }
                        field("Target °F") {
                            TextField("2000", value: $seg.target, format: .number).keyboardType(.numberPad)
                        }
                        field("Hold m") {
                            TextField("0", value: $seg.hold, format: .number).keyboardType(.numberPad)
                        }
                        Button(role: .destructive) { segments.removeAll { $0.id == seg.id } } label: {
                            Image(systemName: "minus.circle").foregroundStyle(Brand.danger)
                        }.accessibilityLabel("Remove segment")
                    }
                    Button("Set target to cone \(targetCone) peak") {
                        if let p = ConeMath.peakF(cone: targetCone, fast: fastRamp) { seg.target = Double(p); Haptics.selection() }
                    }
                    .font(.caption2).foregroundStyle(Brand.live).frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(8).background(Brand.hairline.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
            }
            if !segments.isEmpty {
                let hrs = ConeMath.totalHours(start: startTempF,
                    segments: segments.map { ConeMath.Segment(rate: $0.rate, target: $0.target, hold: $0.hold) })
                Text("Estimated total: \(ConeMath.formatHours(hrs))").font(.caption).foregroundStyle(Brand.text2)
            }
        }
        .glassCard()
    }

    private func field<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(Brand.mono(9)).foregroundStyle(Brand.text3)
            content().font(Brand.mono(14)).foregroundStyle(Brand.text)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity)
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Result")
            Picker("Result", selection: $result) { ForEach(results, id: \.self) { Text($0).tag($0) } }
                .pickerStyle(.segmented)
            TextField("Result notes…", text: $resultNotes, axis: .vertical)
                .lineLimit(2...5).font(.subheadline).foregroundStyle(Brand.text)
        }
        .glassCard()
    }

    private func load() {
        guard let f = existing else { return }
        name = f.name; date = f.date; kind = f.kind; targetCone = f.targetCone
        atmosphere = f.atmosphere; fastRamp = f.fastRamp; startTempF = f.startTempF
        result = f.result; resultNotes = f.resultNotes
        segments = f.orderedSegments.map { SegDraft(rate: $0.rate, target: $0.targetTempF, hold: $0.holdMinutes) }
    }

    private func save() {
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let f: Firing
        if let existing { f = existing } else { f = Firing(name: t); context.insert(f) }
        f.name = t; f.date = date; f.kind = kind; f.targetCone = targetCone
        f.atmosphere = atmosphere; f.fastRamp = fastRamp; f.startTempF = startTempF
        f.result = result; f.resultNotes = resultNotes
        for old in f.segments { context.delete(old) }
        f.segments = []
        for (i, d) in segments.enumerated() {
            let seg = FiringSegment(order: i, rate: max(0, d.rate), targetTempF: d.target, holdMinutes: max(0, d.hold))
            seg.firing = f
            context.insert(seg)
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
