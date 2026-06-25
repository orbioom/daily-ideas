import SwiftUI
import SwiftData

struct LogSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allSettings: [SurfSettings]
    @Query private var spots: [SurfSpot]
    @Query private var boards: [Board]

    private let existing: SurfSession?

    @State private var date: Date
    @State private var spotName: String
    @State private var boardName: String
    @State private var durationMinutes: Int
    @State private var waveHeightFt: Double
    @State private var swellPeriodSec: Int
    @State private var windSpeedKnots: Double
    @State private var windDirection: WindDirection
    @State private var conditions: SessionConditions
    @State private var rating: Int
    @State private var notes: String
    @State private var showError = false

    private var settings: SurfSettings? { allSettings.first }

    init(session: SurfSession?) {
        self.existing = session
        _date = State(initialValue: session?.date ?? .now)
        _spotName = State(initialValue: session?.spotName ?? "")
        _boardName = State(initialValue: session?.boardName ?? "")
        _durationMinutes = State(initialValue: session?.durationMinutes ?? 90)
        _waveHeightFt = State(initialValue: session?.waveHeightFt ?? 3.0)
        _swellPeriodSec = State(initialValue: session?.swellPeriodSec ?? 12)
        _windSpeedKnots = State(initialValue: session?.windSpeedKnots ?? 10.0)
        _windDirection = State(initialValue: session?.windDirection ?? .w)
        _conditions = State(initialValue: session?.conditions ?? .good)
        _rating = State(initialValue: session?.rating ?? 3)
        _notes = State(initialValue: session?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])

                    HStack {
                        Text("Spot")
                        Spacer()
                        TextField("Spot name", text: $spotName)
                            .multilineTextAlignment(.trailing)
                    }

                    if !spots.isEmpty {
                        Menu("Pick from saved spots") {
                            ForEach(spots) { spot in
                                Button(spot.name) { spotName = spot.name }
                            }
                        }
                        .foregroundStyle(SwellTheme.teal)
                    }

                    HStack {
                        Text("Board")
                        Spacer()
                        TextField("Board name", text: $boardName)
                            .multilineTextAlignment(.trailing)
                    }

                    if !boards.isEmpty {
                        Menu("Pick from quiver") {
                            ForEach(boards) { board in
                                Button("\(board.name) (\(board.displayLength))") { boardName = board.name }
                            }
                        }
                        .foregroundStyle(SwellTheme.teal)
                    }
                }

                Section("Conditions") {
                    Picker("Conditions", selection: $conditions) {
                        ForEach(SessionConditions.allCases) { c in
                            Label(c.rawValue, systemImage: c.sfSymbol).tag(c)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Wave Height")
                            Spacer()
                            Text(String(format: "%.1f ft", waveHeightFt))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $waveHeightFt, in: 0.5...25.0, step: 0.5)
                            .tint(SwellTheme.teal)
                            .accessibilityLabel("Wave height: \(String(format: "%.1f", waveHeightFt)) feet")
                    }

                    Stepper("Swell Period: \(swellPeriodSec)s", value: $swellPeriodSec, in: 4...25)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Wind Speed")
                            Spacer()
                            Text(String(format: "%.0f kts", windSpeedKnots))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $windSpeedKnots, in: 0...60, step: 1)
                            .tint(SwellTheme.teal)
                            .accessibilityLabel("Wind speed: \(Int(windSpeedKnots)) knots")
                    }

                    Picker("Wind Direction", selection: $windDirection) {
                        ForEach(WindDirection.allCases) { d in
                            Text(d.rawValue).tag(d)
                        }
                    }
                }

                Section("Duration & Rating") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text(formatDuration(durationMinutes))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(durationMinutes) },
                            set: { durationMinutes = Int($0) }
                        ), in: 15...360, step: 15)
                        .tint(SwellTheme.teal)
                        .accessibilityLabel("Duration: \(formatDuration(durationMinutes))")
                    }

                    HStack {
                        Text("Rating")
                        Spacer()
                        EditableRatingView(rating: $rating)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Session notes")
                }
            }
            .navigationTitle(existing == nil ? "Log Session" : "Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(spotName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                        .foregroundStyle(SwellTheme.teal)
                        .accessibilityLabel("Save session")
                }
            }
            .alert("Please enter a spot name.", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    private func save() {
        let trimmed = spotName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { showError = true; return }

        if let s = existing {
            s.date = date
            s.spotName = trimmed
            s.boardName = boardName
            s.durationMinutes = durationMinutes
            s.waveHeightFt = waveHeightFt
            s.swellPeriodSec = swellPeriodSec
            s.windSpeedKnots = windSpeedKnots
            s.windDirection = windDirection
            s.conditions = conditions
            s.rating = rating
            s.notes = notes
        } else {
            let session = SurfSession(
                date: date,
                spotName: trimmed,
                boardName: boardName,
                durationMinutes: durationMinutes,
                waveHeightFt: waveHeightFt,
                swellPeriodSec: swellPeriodSec,
                windSpeedKnots: windSpeedKnots,
                windDirection: windDirection,
                conditions: conditions,
                rating: rating,
                notes: notes
            )
            context.insert(session)
        }

        if settings?.hapticsEnabled == true { HapticManager.success() }
        try? context.save()
        dismiss()
    }
}

struct EditableRatingView: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Button {
                    rating = i
                } label: {
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(i <= rating ? SwellTheme.teal : Color.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rate \(i) star\(i == 1 ? "" : "s")")
                .accessibilityAddTraits(i == rating ? .isSelected : [])
            }
        }
    }
}
