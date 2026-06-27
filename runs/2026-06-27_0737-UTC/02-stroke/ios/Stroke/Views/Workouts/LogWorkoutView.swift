import SwiftUI
import SwiftData

struct LogWorkoutView: View {
    var editing: RowWorkout? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var prs: [RowPR]

    @State private var workoutType = WorkoutType.distance
    @State private var date = Date()
    @State private var distanceText = ""
    @State private var splitMinText = ""
    @State private var splitSecText = ""
    @State private var durationMinText = ""
    @State private var durationSecText = ""
    @State private var strokeRate = 22
    @State private var rating = StrokeRating.three
    @State private var notes = ""
    @State private var showValidation = false
    @State private var validationMessage = ""
    @State private var showNewPR = false
    @State private var newPRCategories: [PRCategory] = []

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    Picker("Type", selection: $workoutType) {
                        ForEach(WorkoutType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                Section("Distance") {
                    HStack {
                        Text("Distance")
                        Spacer()
                        TextField("e.g. 2000", text: $distanceText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("m").foregroundStyle(.secondary)
                    }
                }
                Section("Time") {
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("mm", text: $durationMinText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                        Text(":").fontWeight(.bold)
                        TextField("ss", text: $durationSecText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                    }
                }
                Section("500m Split (optional)") {
                    HStack {
                        Text("Split")
                        Spacer()
                        TextField("mm", text: $splitMinText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                        Text(":").fontWeight(.bold)
                        TextField("ss", text: $splitSecText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                        Text("/500m").foregroundStyle(.secondary)
                    }
                }
                Section("Metrics") {
                    Stepper("Stroke Rate: \(strokeRate) SPM", value: $strokeRate, in: 14...40)
                    HStack {
                        Text("Rating")
                        Spacer()
                        Picker("Rating", selection: $rating) {
                            ForEach(StrokeRating.allCases, id: \.self) { r in
                                Text(r.label).tag(r)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                Section("Notes") {
                    TextField("How did it feel?", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle(isEditing ? "Edit Workout" : "Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(distanceText.isEmpty)
                }
            }
            .alert("Check Input", isPresented: $showValidation) {
                Button("OK", role: .cancel) {}
            } message: { Text(validationMessage) }
            .alert("New PR! 🏆", isPresented: $showNewPR) {
                Button("Awesome!", role: .cancel) {}
            } message: {
                Text(newPRCategories.map { $0.rawValue }.joined(separator: ", "))
            }
        }
        .onAppear { populate() }
    }

    private func populate() {
        guard let w = editing else { return }
        workoutType = w.workoutType
        date = w.date
        distanceText = "\(w.distanceM)"
        let dm = w.timeSeconds / 60
        let ds = w.timeSeconds % 60
        durationMinText = "\(dm)"
        durationSecText = ds > 0 ? "\(ds)" : ""
        let sm = w.avgSplitSeconds / 60
        let ss = w.avgSplitSeconds % 60
        splitMinText = "\(sm)"
        splitSecText = ss > 0 ? "\(ss)" : ""
        strokeRate = w.avgStrokeRate
        rating = w.rating
        notes = w.notes
    }

    private func save() {
        guard let dist = Int(distanceText), dist > 0 else {
            validationMessage = "Enter a valid distance in meters."
            showValidation = true
            return
        }
        let dm = Int(durationMinText) ?? 0
        let ds = Int(durationSecText) ?? 0
        let totalSec = dm * 60 + ds
        let sm = Int(splitMinText) ?? 0
        let ss = Int(splitSecText) ?? 0
        let splitSec = sm > 0 || ss > 0 ? sm * 60 + ss : (totalSec > 0 && dist > 0 ? totalSec * 500 / dist : 0)
        let watts = splitSec > 0 ? RowEngine.splitToWatts(splitSec) : 0

        if let w = editing {
            w.date = date
            w.workoutTypeRaw = workoutType.rawValue
            w.distanceM = dist
            w.timeSeconds = totalSec
            w.avgSplitSeconds = splitSec
            w.avgStrokeRate = strokeRate
            w.avgWatts = watts
            w.ratingRaw = rating.rawValue
            w.notes = notes
        } else {
            let w = RowWorkout(
                date: date, type: workoutType,
                distanceM: dist, timeSeconds: totalSec,
                avgSplitSeconds: splitSec, avgStrokeRate: strokeRate,
                avgWatts: watts, rating: rating, notes: notes
            )
            context.insert(w)
            // Check PRs
            let newCats = RowEngine.checkPR(workout: w, existing: prs)
            if !newCats.isEmpty {
                for cat in newCats {
                    let val = cat.isDistance ? totalSec : dist
                    let existing = prs.first { $0.category == cat }
                    if let ex = existing {
                        ex.value = val
                        ex.achievedDate = date
                        ex.workoutID = w.id
                    } else {
                        let pr = RowPR(category: cat, value: val, achievedDate: date, workoutID: w.id)
                        context.insert(pr)
                    }
                }
                newPRCategories = newCats
                showNewPR = true
            }
        }
        try? context.save()
        if !showNewPR { dismiss() }
    }
}
