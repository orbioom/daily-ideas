import SwiftUI
import SwiftData

/// Add or edit a single wear log entry for a fragrance.
struct WearLogEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    let fragrance: Fragrance
    var existing: WearLog?

    @State private var date = Date()
    @State private var season: Season?
    @State private var occasion: Occasion?
    @State private var note = ""
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date worn", selection: $date, in: ...Date(), displayedComponents: .date)
                }
                Section {
                    Picker("Season", selection: $season) {
                        Text("Unspecified").tag(Season?.none)
                        ForEach(Season.allCases) { s in
                            Text(s.rawValue).tag(Season?.some(s))
                        }
                    }
                    Picker("Occasion", selection: $occasion) {
                        Text("Unspecified").tag(Occasion?.none)
                        ForEach(Occasion.allCases) { o in
                            Text(o.rawValue).tag(Occasion?.some(o))
                        }
                    }
                } header: {
                    Text("Context")
                }
                Section {
                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(existing == nil ? "Log a Wear" : "Edit Wear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.font(Theme.rounded(17, .semibold))
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        if let existing {
            date = existing.date
            season = existing.season
            occasion = existing.occasion
            note = existing.note
        } else {
            season = Season.current()
        }
    }

    private func save() {
        if let existing {
            existing.date = date
            existing.season = season
            existing.occasion = occasion
            existing.note = note
        } else {
            let log = WearLog(date: date, occasion: occasion, season: season, note: note)
            log.fragrance = fragrance
            fragrance.wears.append(log)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
