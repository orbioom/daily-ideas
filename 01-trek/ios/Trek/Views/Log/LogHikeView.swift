import SwiftUI
import SwiftData
import PhotosUI

struct LogHikeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(TrekSettings.hapticFeedback) private var hapticEnabled = true

    var preselectedTrail: Trail? = nil
    var trails: [Trail]

    @State private var selectedTrail: Trail? = nil
    @State private var date: Date = Date()
    @State private var durationHours: String = ""
    @State private var durationMinutes: String = "60"
    @State private var distanceKm: String = ""
    @State private var elevationGainM: String = ""
    @State private var rating: Int = 0
    @State private var notes: String = ""
    @State private var showTrailPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Trail") {
                    Button {
                        showTrailPicker = true
                    } label: {
                        HStack {
                            Text(selectedTrail?.name ?? "Choose a trail (optional)")
                                .foregroundStyle(selectedTrail == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .accessibilityHidden(true)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Distance & Elevation") {
                    HStack {
                        TextField("Distance", text: $distanceKm)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Distance in kilometers")
                        Text("km")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("Elevation gain", text: $elevationGainM)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Elevation gain in meters")
                        Text("m")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Duration") {
                    HStack {
                        TextField("Minutes", text: $durationMinutes)
                            .keyboardType(.numberPad)
                            .accessibilityLabel("Duration in minutes")
                        Text("min")
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
                            .accessibilityLabel("\(i) star\(i > 1 ? "s" : "")")
                            .accessibilityAddTraits(i <= rating ? .isSelected : [])
                        }
                        Spacer()
                        if rating > 0 {
                            Text("\(rating)/5")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Hike notes")
                }
            }
            .navigationTitle("Log Hike")
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
            .sheet(isPresented: $showTrailPicker) {
                TrailPickerSheet(trails: trails, selected: $selectedTrail)
            }
            .onAppear {
                selectedTrail = preselectedTrail
                if let t = preselectedTrail {
                    if t.distanceKm > 0 {
                        distanceKm = String(format: "%.1f", t.distanceKm)
                    }
                    if t.elevationGainM > 0 {
                        elevationGainM = String(format: "%.0f", t.elevationGainM)
                    }
                }
            }
        }
    }

    private func save() {
        let mins = Int(durationMinutes) ?? 0
        let dist = Double(distanceKm.replacingOccurrences(of: ",", with: ".")) ?? 0
        let elev = Double(elevationGainM.replacingOccurrences(of: ",", with: ".")) ?? 0

        let session = HikeSession(
            date: date,
            durationMinutes: max(1, mins),
            distanceKm: dist,
            elevationGainM: elev,
            rating: rating,
            notes: notes
        )

        context.insert(session)

        if let trail = selectedTrail {
            session.trail = trail
            trail.sessions.append(session)
        }

        if hapticEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        dismiss()
    }
}

struct TrailPickerSheet: View {
    let trails: [Trail]
    @Binding var selected: Trail?
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    var filtered: [Trail] {
        guard !search.isEmpty else { return trails }
        return trails.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                Button("No trail (quick hike)") {
                    selected = nil
                    dismiss()
                }
                .foregroundStyle(.secondary)

                ForEach(filtered) { trail in
                    Button {
                        selected = trail
                        dismiss()
                    } label: {
                        HStack {
                            Text(trail.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selected?.id == trail.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(TrekTheme.forestGreen)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search trails")
            .navigationTitle("Select Trail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
