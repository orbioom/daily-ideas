import SwiftUI
import SwiftData

struct SetlistEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let existing: Setlist?
    @State private var name = ""
    @State private var venue = ""
    @State private var date = Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Setlist name", text: $name).font(.headline).foregroundStyle(Brand.text)
                        Divider().overlay(Brand.hairline)
                        TextField("Venue", text: $venue).foregroundStyle(Brand.text2)
                        Divider().overlay(Brand.hairline)
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .tint(Brand.text).foregroundStyle(Brand.text2)
                    }
                    .font(.subheadline).glassCard()
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Notes")
                        TextField("Set notes…", text: $notes, axis: .vertical)
                            .lineLimit(2...5).font(.subheadline).foregroundStyle(Brand.text)
                    }.glassCard()
                }.padding()
            }
            .navigationTitle(existing == nil ? "New Setlist" : "Edit Setlist")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let e = existing { name = e.name; venue = e.venue; date = e.date; notes = e.notes }
            }
        }
    }

    private func save() {
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let s: Setlist
        if let existing { s = existing } else { s = Setlist(name: t); context.insert(s) }
        s.name = t; s.venue = venue; s.date = date; s.notes = notes
        try? context.save(); Haptics.success(); dismiss()
    }
}
