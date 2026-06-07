import SwiftUI
import SwiftData

struct ObservationEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("homeBortle") private var homeBortle = 5
    @Query(sort: \Telescope.name) private var scopes: [Telescope]
    @Query(sort: \Eyepiece.focalLength, order: .reverse) private var eyepieces: [Eyepiece]

    var observation: Observation?
    var prefillTarget: SkyTarget?

    @State private var date = Date.now
    @State private var targetName = ""
    @State private var targetType: TargetType = .galaxy
    @State private var constellation = ""
    @State private var scopeName = ""
    @State private var eyepieceName = ""
    @State private var location = ""
    @State private var bortle = 5
    @State private var seeing = 3
    @State private var transparency = 3
    @State private var rating = 3
    @State private var notes = ""
    @State private var loaded = false

    private var computedMag: Double {
        guard let s = scopes.first(where: { $0.name == scopeName }),
              let e = eyepieces.first(where: { $0.name == eyepieceName }) else { return 0 }
        return Optics.magnification(scopeFL: s.focalLength, eyepieceFL: e.focalLength)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Target") {
                        TextField("Name", text: $targetName)
                        Picker("Type", selection: $targetType) {
                            ForEach(TargetType.allCases) { t in Text(t.label).tag(t) }
                        }
                        TextField("Constellation", text: $constellation)
                        DatePicker("When", selection: $date)
                    }.listRowBackground(Color.clear)

                    Section("Gear") {
                        Picker("Telescope", selection: $scopeName) {
                            Text("None").tag("")
                            ForEach(scopes) { s in Text(s.name).tag(s.name) }
                        }
                        Picker("Eyepiece", selection: $eyepieceName) {
                            Text("None").tag("")
                            ForEach(eyepieces) { e in Text("\(Int(e.focalLength))mm \(e.name)").tag(e.name) }
                        }
                        if computedMag > 0 {
                            LabeledContent("Magnification", value: Fmt.mag(computedMag))
                        }
                    }.listRowBackground(Color.clear)

                    Section("Conditions") {
                        TextField("Location", text: $location)
                        Stepper("Bortle: \(bortle)", value: $bortle, in: 1...9)
                        Stepper("Seeing: \(seeing)/5", value: $seeing, in: 1...5)
                        Stepper("Transparency: \(transparency)/5", value: $transparency, in: 1...5)
                    }.listRowBackground(Color.clear)

                    Section("Rating") {
                        Stepper("Rating: \(rating)/5", value: $rating, in: 1...5)
                        TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...5)
                    }.listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(observation == nil ? "Log observation" : "Edit observation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(targetName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let o = observation {
            date = o.date; targetName = o.targetName; targetType = o.targetType
            constellation = o.constellation; scopeName = o.telescopeName; eyepieceName = o.eyepieceName
            location = o.location; bortle = o.bortle; seeing = o.seeing
            transparency = o.transparency; rating = o.rating; notes = o.notes
        } else {
            bortle = homeBortle
            scopeName = (scopes.first { $0.isPrimary } ?? scopes.first)?.name ?? ""
            eyepieceName = eyepieces.first?.name ?? ""
            if let t = prefillTarget {
                targetName = t.name; targetType = t.type; constellation = t.constellation
            }
        }
    }

    private func save() {
        let mag = computedMag
        if let o = observation {
            o.date = date; o.targetName = targetName; o.targetTypeRaw = targetType.rawValue
            o.constellation = constellation; o.telescopeName = scopeName; o.eyepieceName = eyepieceName
            o.magnification = mag; o.location = location; o.bortle = bortle
            o.seeing = seeing; o.transparency = transparency; o.rating = rating; o.notes = notes
        } else {
            let o = Observation(date: date, targetName: targetName, targetType: targetType,
                                constellation: constellation, telescopeName: scopeName,
                                eyepieceName: eyepieceName, magnification: mag, location: location,
                                bortle: bortle, seeing: seeing, transparency: transparency,
                                rating: rating, notes: notes)
            context.insert(o)
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
