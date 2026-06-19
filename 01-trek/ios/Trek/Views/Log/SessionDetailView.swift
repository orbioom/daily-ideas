import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: HikeSession
    @AppStorage(TrekSettings.distanceUnit) private var distanceUnitRaw = DistanceUnit.km.rawValue
    @AppStorage(TrekSettings.elevationUnit) private var elevationUnitRaw = ElevationUnit.meters.rawValue
    @State private var isEditing = false

    private var distanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .km }
    private var elevationUnit: ElevationUnit { ElevationUnit(rawValue: elevationUnitRaw) ?? .meters }

    var body: some View {
        List {
            Section("Hike Summary") {
                if let trail = session.trail {
                    LabeledContent("Trail", value: trail.name)
                }
                LabeledContent("Date", value: session.date.formatted(date: .long, time: .omitted))
                LabeledContent("Duration", value: session.durationFormatted)
                LabeledContent("Distance", value: distanceUnit.label(session.distanceKm))
                LabeledContent("Elevation Gain", value: elevationUnit.label(session.elevationGainM))
                if let pace = session.paceMinPerKm {
                    LabeledContent("Avg Pace",
                        value: String(format: "%.0f:%02.0f /km",
                            (pace).truncatingRemainder(dividingBy: 60) == 0 ? pace : floor(pace),
                            ((pace - floor(pace)) * 60)))
                }
            }

            if session.rating > 0 {
                Section("Rating") {
                    StarRatingView(rating: session.rating)
                        .padding(.vertical, 4)
                }
            }

            if !session.notes.isEmpty {
                Section("Notes") {
                    Text(session.notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Hike Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditSessionView(session: session)
        }
    }
}

struct EditSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: HikeSession

    @State private var date: Date = Date()
    @State private var durationMinutes: String = ""
    @State private var distanceKm: String = ""
    @State private var elevationGainM: String = ""
    @State private var rating: Int = 0
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Stats") {
                    HStack {
                        TextField("Minutes", text: $durationMinutes)
                            .keyboardType(.numberPad)
                        Text("min")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("Distance", text: $distanceKm)
                            .keyboardType(.decimalPad)
                        Text("km")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("Elevation gain", text: $elevationGainM)
                            .keyboardType(.decimalPad)
                        Text("m")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Rating") {
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                rating = rating == i ? 0 : i
                            } label: {
                                Image(systemName: i <= rating ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundStyle(i <= rating ? TrekTheme.sunGold : .secondary)
                            }
                        }
                        Spacer()
                    }
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Edit Hike")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                date = session.date
                durationMinutes = "\(session.durationMinutes)"
                distanceKm = session.distanceKm > 0 ? String(format: "%.1f", session.distanceKm) : ""
                elevationGainM = session.elevationGainM > 0 ? String(format: "%.0f", session.elevationGainM) : ""
                rating = session.rating
                notes = session.notes
            }
        }
    }

    private func save() {
        session.date = date
        session.durationMinutes = max(1, Int(durationMinutes) ?? 1)
        session.distanceKm = Double(distanceKm.replacingOccurrences(of: ",", with: ".")) ?? 0
        session.elevationGainM = Double(elevationGainM.replacingOccurrences(of: ",", with: ".")) ?? 0
        session.rating = rating
        session.notes = notes
        dismiss()
    }
}
