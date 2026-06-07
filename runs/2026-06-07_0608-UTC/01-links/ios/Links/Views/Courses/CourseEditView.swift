import SwiftUI
import SwiftData

/// Create or edit a course: name, location, hole count, per-hole par and stroke
/// index, and a set of tees with rating and slope.
struct CourseEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let existing: Course?

    @State private var name = ""
    @State private var location = ""
    @State private var holeCount = 18
    @State private var pars: [Int] = Array(repeating: 4, count: 18)
    @State private var strokeIndex: [Int] = Array(1...18)
    @State private var tees: [TeeDraft] = []
    @State private var error: String?

    struct TeeDraft: Identifiable {
        let id = UUID()
        var name: String
        var rating: Double
        var slope: Int
        var yardage: Int
    }

    private var siValid: Bool {
        Set(strokeIndex.prefix(holeCount)) == Set(1...holeCount)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    basicsCard
                    holesCard
                    teesCard
                    if let error {
                        Text(error).font(.caption).foregroundStyle(Brand.danger)
                    }
                }
                .padding()
            }
            .navigationTitle(existing == nil ? "New Course" : "Edit Course")
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
            TextField("Course name", text: $name).font(.headline).foregroundStyle(Brand.text)
            Divider().overlay(Brand.hairline)
            TextField("Location (optional)", text: $location).font(.subheadline).foregroundStyle(Brand.text2)
            Divider().overlay(Brand.hairline)
            Picker("Holes", selection: $holeCount) {
                Text("18 holes").tag(18)
                Text("9 holes").tag(9)
            }
            .pickerStyle(.segmented)
            .onChange(of: holeCount) { _, n in resize(n) }
        }
        .glassCard()
    }

    private var holesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(text: "Holes")
                Spacer()
                Text("Par \(pars.prefix(holeCount).reduce(0, +))")
                    .font(Brand.mono(13, weight: .semibold)).foregroundStyle(Brand.text2)
            }
            if !siValid {
                Text("Stroke index should use each of 1…\(holeCount) once.")
                    .font(.caption).foregroundStyle(Brand.warn)
            }
            ForEach(0..<holeCount, id: \.self) { i in
                HStack {
                    Text("\(i + 1)").font(Brand.mono(14, weight: .bold)).foregroundStyle(Brand.text).frame(width: 26)
                    Stepper("Par \(pars[i])", value: $pars[i], in: 3...6).fixedSize()
                        .font(.subheadline).foregroundStyle(Brand.text2)
                    Spacer()
                    Stepper("SI \(strokeIndex[i])", value: $strokeIndex[i], in: 1...holeCount).fixedSize()
                        .font(.subheadline).foregroundStyle(Brand.text2)
                }
                if i < holeCount - 1 { Divider().overlay(Brand.hairline) }
            }
        }
        .glassCard()
    }

    private var teesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(text: "Tees")
                Spacer()
                Button {
                    tees.append(TeeDraft(name: "New", rating: 72.0, slope: 113, yardage: 6000))
                    Haptics.tap()
                } label: { Image(systemName: "plus.circle") }
                .accessibilityLabel("Add tee")
            }
            if tees.isEmpty {
                Text("Add at least one tee with its course rating and slope.")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            ForEach($tees) { $tee in
                VStack(spacing: 8) {
                    HStack {
                        TextField("Tee name", text: $tee.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                        Spacer()
                        Button(role: .destructive) {
                            tees.removeAll { $0.id == tee.id }
                        } label: { Image(systemName: "trash") }
                        .accessibilityLabel("Remove tee \(tee.name)")
                    }
                    HStack(spacing: 16) {
                        labeledField("CR") {
                            TextField("72.0", value: $tee.rating, format: .number)
                                .keyboardType(.decimalPad)
                        }
                        labeledField("Slope") {
                            TextField("113", value: $tee.slope, format: .number)
                                .keyboardType(.numberPad)
                        }
                        labeledField("Yards") {
                            TextField("6000", value: $tee.yardage, format: .number)
                                .keyboardType(.numberPad)
                        }
                    }
                }
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .glassCard()
    }

    private func labeledField<Content: View>(_ label: String, @ViewBuilder _ field: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(Brand.mono(10)).foregroundStyle(Brand.text3)
            field()
                .font(Brand.mono(14)).foregroundStyle(Brand.text)
        }
    }

    private func resize(_ n: Int) {
        if pars.count < n { pars += Array(repeating: 4, count: n - pars.count) }
        if strokeIndex.count < n {
            let existing = Set(strokeIndex.prefix(n))
            var next = strokeIndex
            for v in 1...n where !existing.contains(v) { next.append(v) }
            strokeIndex = next
        }
        strokeIndex = Array(strokeIndex.prefix(n))
        if strokeIndex.count < n { strokeIndex += Array((strokeIndex.count+1)...n) }
    }

    private func load() {
        guard let c = existing else {
            resize(18); return
        }
        name = c.name; location = c.location
        holeCount = c.holeCount
        pars = c.holePars
        strokeIndex = c.holeStrokeIndex
        tees = c.sortedTees.map { TeeDraft(name: $0.name, rating: $0.courseRating, slope: $0.slopeRating, yardage: $0.yardage) }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let p = Array(pars.prefix(holeCount))
        var si = Array(strokeIndex.prefix(holeCount))
        if Set(si) != Set(1...holeCount) { si = Array(1...holeCount) }  // normalise
        let c: Course
        if let existing { c = existing } else {
            c = Course(name: trimmed, location: location, holePars: p, holeStrokeIndex: si)
            context.insert(c)
        }
        c.name = trimmed
        c.location = location
        c.holePars = p
        c.holeStrokeIndex = si
        // rebuild tees
        for t in c.tees { context.delete(t) }
        c.tees = tees
            .filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { d in
                let t = Tee(name: d.name, courseRating: d.rating,
                            slopeRating: max(55, min(155, d.slope)), yardage: max(0, d.yardage))
                return t
            }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
