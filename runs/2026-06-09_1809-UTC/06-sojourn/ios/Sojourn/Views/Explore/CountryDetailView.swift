import SwiftUI
import SwiftData

/// The core CRUD editor for a single country. Upserts a `VisitMark` by code:
/// set status, first-visit year, times visited, favorite, and a note — or clear
/// the mark entirely. Presented as a sheet from Explore / Wishlist / Trips.
struct CountryDetailView: View {
    let country: Country

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// The existing mark for this country, if any (one per code).
    @Query private var marks: [VisitMark]

    // Draft state — initialized from any existing mark in `.onAppear`.
    @State private var status: VisitStatus = .visited
    @State private var hasYear = false
    @State private var year = Calendar.current.component(.year, from: .now)
    @State private var times = 1
    @State private var isFavorite = false
    @State private var note = ""
    @State private var loaded = false

    private let minYear = 1950

    init(country: Country) {
        self.country = country
        let code = country.code.uppercased()
        _marks = Query(filter: #Predicate<VisitMark> { $0.countryCode == code })
    }

    private var existing: VisitMark? { marks.first }
    private var currentYear: Int { Calendar.current.component(.year, from: .now) }

    var body: some View {
        NavigationStack {
            Form {
                headerSection
                statusSection
                if status.isGrounded || status == .transit {
                    detailsSection
                }
                noteSection
                if existing != nil {
                    Section {
                        Button(role: .destructive) {
                            clearMark()
                        } label: {
                            Label("Clear this country", systemImage: "xmark.circle")
                        }
                    } footer: {
                        Text("Removes \(country.name) from your map entirely.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(country.name)
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
            .onAppear(perform: loadIfNeeded)
        }
    }

    // MARK: Sections

    private var headerSection: some View {
        Section {
            HStack(spacing: 14) {
                Text(country.flagEmoji)
                    .font(.system(size: 44))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(country.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Brand.text)
                    Text("\(country.region) · \(country.continent.label)")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                    Label(country.capital, systemImage: "building.columns")
                        .font(.footnote)
                        .foregroundStyle(Brand.text3)
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(country.name), \(country.continent.label), capital \(country.capital)")
        }
    }

    private var statusSection: some View {
        Section("Status") {
            Picker("Status", selection: $status) {
                ForEach(VisitStatus.allCases) { s in
                    Label(s.label, systemImage: s.symbol).tag(s)
                }
            }
            .pickerStyle(.segmented)
            Toggle(isOn: $isFavorite) {
                Label("Favorite", systemImage: isFavorite ? "star.fill" : "star")
            }
        }
    }

    private var detailsSection: some View {
        Section("Visit details") {
            Toggle("Remember first-visit year", isOn: $hasYear.animation(Brand.ease(0.25)))
            if hasYear {
                Picker("First visited", selection: $year) {
                    ForEach((minYear...currentYear).reversed(), id: \.self) { y in
                        Text(String(y)).tag(y)
                    }
                }
            }
            Stepper(value: $times, in: 1...99) {
                HStack {
                    Text("Times visited")
                    Spacer()
                    Text("\(times)")
                        .font(Brand.mono(15, weight: .semibold))
                        .foregroundStyle(Brand.text2)
                }
            }
            .accessibilityValue("\(times) times")
        }
    }

    private var noteSection: some View {
        Section("Note") {
            TextField("A memory, a tip, a plan…", text: $note, axis: .vertical)
                .lineLimit(2...5)
        }
    }

    // MARK: Logic

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        if let m = existing {
            status = m.status
            if let y = m.firstVisitYear {
                hasYear = true
                year = min(max(y, minYear), currentYear)
            }
            times = max(1, m.timesVisited)
            isFavorite = m.isFavorite
            note = m.note
        }
    }

    private func save() {
        let mark = existing ?? {
            let m = VisitMark(countryCode: country.code)
            context.insert(m)
            return m
        }()
        mark.status = status
        mark.firstVisitYear = (status.isGrounded || status == .transit) && hasYear ? year : nil
        mark.timesVisited = (status.isGrounded || status == .transit) ? times : 0
        mark.isFavorite = isFavorite
        mark.note = note
        mark.updatedAt = .now
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func clearMark() {
        if let m = existing {
            context.delete(m)
            try? context.save()
            Haptics.warning()
        }
        dismiss()
    }
}
