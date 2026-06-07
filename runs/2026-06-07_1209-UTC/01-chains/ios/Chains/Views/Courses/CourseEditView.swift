import SwiftUI
import SwiftData

/// Create or edit a course and its holes. Holes are added/removed and each has a
/// par and distance.
struct CourseEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("chains.units") private var units = "feet"

    /// nil = create new.
    var course: DiscCourse?

    @State private var name = ""
    @State private var location = ""
    @State private var holeCount = 18
    @State private var pars: [Int] = Array(repeating: 3, count: 18)
    @State private var distances: [Int] = Array(repeating: 300, count: 18)
    @State private var ssa = 54.0
    @State private var autoSSA = true

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var computedPar: Int { pars.prefix(holeCount).reduce(0, +) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Course")
                        TextField("Course name", text: $name)
                            .textFieldStyle(.roundedBorder)
                        TextField("Location (optional)", text: $location)
                            .textFieldStyle(.roundedBorder)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Holes")
                        Stepper("\(holeCount) holes", value: $holeCount, in: 1...36)
                            .onChange(of: holeCount) { _, n in resize(to: n) }
                            .foregroundStyle(Brand.text)
                        Divider().overlay(Brand.hairline)
                        ForEach(0..<holeCount, id: \.self) { i in
                            HoleEditRow(index: i, par: bindingPar(i), distance: bindingDist(i), units: units)
                            if i < holeCount - 1 { Divider().overlay(Brand.hairline) }
                        }
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Rating baseline")
                        Toggle("Use course par as baseline", isOn: $autoSSA)
                            .tint(Brand.live).foregroundStyle(Brand.text)
                        if !autoSSA {
                            HStack {
                                Text("Scratch average (SSA)").foregroundStyle(Brand.text2).font(.subheadline)
                                Spacer()
                                TextField("SSA", value: $ssa, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 70)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        Text("A round equal to the baseline rates about 1000. Lower it if a scratch player typically beats par here.")
                            .font(.caption).foregroundStyle(Brand.text3)
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle(course == nil ? "New course" : "Edit course")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.tint(Brand.text2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.tint(Brand.text)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func bindingPar(_ i: Int) -> Binding<Int> {
        Binding(get: { pars.indices.contains(i) ? pars[i] : 3 },
                set: { if pars.indices.contains(i) { pars[i] = $0 } })
    }
    private func bindingDist(_ i: Int) -> Binding<Int> {
        Binding(get: { distances.indices.contains(i) ? distances[i] : 0 },
                set: { if distances.indices.contains(i) { distances[i] = $0 } })
    }

    private func resize(to n: Int) {
        if n > pars.count {
            pars.append(contentsOf: Array(repeating: 3, count: n - pars.count))
            distances.append(contentsOf: Array(repeating: 300, count: n - distances.count))
        }
    }

    private func load() {
        guard let course else { resize(to: holeCount); return }
        name = course.name
        location = course.location
        let holes = course.orderedHoles
        holeCount = max(1, holes.count)
        pars = holes.map { $0.par }
        distances = holes.map { $0.distanceFeet }
        resize(to: holeCount)
        ssa = course.ssa
        autoSSA = abs(course.ssa - Double(course.par)) < 0.01
    }

    private func save() {
        let target = course ?? DiscCourse(name: trimmedName)
        target.name = trimmedName
        target.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        // rebuild holes
        for h in target.holes { context.delete(h) }
        target.holes.removeAll()
        for i in 0..<holeCount {
            let p = pars.indices.contains(i) ? pars[i] : 3
            let d = distances.indices.contains(i) ? distances[i] : 0
            target.holes.append(Hole(number: i + 1, par: p, distanceFeet: d))
        }
        target.ssa = autoSSA ? Double(computedPar) : ssa
        target.pointsPerThrow = RatingEngine.suggestedPointsPerThrow(holeCount: holeCount)
        if course == nil { context.insert(target) }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

private struct HoleEditRow: View {
    let index: Int
    @Binding var par: Int
    @Binding var distance: Int
    let units: String
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(Brand.mono(15, weight: .semibold))
                .foregroundStyle(Brand.text)
                .frame(width: 26, alignment: .leading)
            Picker("Par", selection: $par) {
                ForEach(2...6, id: \.self) { Text("Par \($0)").tag($0) }
            }.pickerStyle(.menu).tint(Brand.text2)
            Spacer()
            HStack(spacing: 6) {
                TextField("Distance", value: $distance, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56)
                    .textFieldStyle(.roundedBorder)
                Text("ft").font(.caption).foregroundStyle(Brand.text3)
            }
        }
    }
}
