import SwiftUI
import SwiftData

/// Record or edit a structured tasting for a bottle. `tasting == nil` adds a new one.
struct TastingEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let bottle: Bottle
    let tasting: Tasting?

    @State private var date = Date.now
    @State private var rating = 3
    @State private var aroma = ""
    @State private var palate = ""
    @State private var finish = ""
    @State private var overallNote = ""
    @State private var flavorTags: [String] = []

    private var isEditing: Bool { tasting != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Date", selection: $date,
                               in: ...Date.now,
                               displayedComponents: [.date])
                }

                Section("Rating") {
                    HStack {
                        Spacer()
                        RatingInput(rating: $rating)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                Section("Flavors") {
                    if bottle.category.flavorLexicon.isEmpty {
                        Text("No descriptors for this category.")
                            .foregroundStyle(Brand.text3)
                    } else {
                        FlavorTagPicker(lexicon: bottle.category.flavorLexicon,
                                        selected: $flavorTags)
                            .padding(.vertical, 4)
                    }
                }

                Section("Aroma · Palate · Finish") {
                    LabeledField(label: "Aroma", text: $aroma)
                    LabeledField(label: "Palate", text: $palate)
                    LabeledField(label: "Finish", text: $finish)
                }

                Section("Overall") {
                    TextField("How did it land?", text: $overallNote, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit tasting" : "New tasting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let tasting else { return }
        date = tasting.date
        rating = tasting.rating
        aroma = tasting.aroma
        palate = tasting.palate
        finish = tasting.finish
        overallNote = tasting.overallNote
        flavorTags = tasting.flavorTags
    }

    private func save() {
        // Rating is constrained by the input control (1...5); fields are free text.
        let cleanTags = flavorTags.map { $0.trimmingCharacters(in: .whitespaces) }
                                  .filter { !$0.isEmpty }
        if let tasting {
            tasting.date = date
            tasting.rating = rating
            tasting.aroma = aroma.trimmingCharacters(in: .whitespacesAndNewlines)
            tasting.palate = palate.trimmingCharacters(in: .whitespacesAndNewlines)
            tasting.finish = finish.trimmingCharacters(in: .whitespacesAndNewlines)
            tasting.overallNote = overallNote.trimmingCharacters(in: .whitespacesAndNewlines)
            tasting.flavorTags = cleanTags
        } else {
            let newTasting = Tasting(
                date: date,
                rating: rating,
                aroma: aroma.trimmingCharacters(in: .whitespacesAndNewlines),
                palate: palate.trimmingCharacters(in: .whitespacesAndNewlines),
                finish: finish.trimmingCharacters(in: .whitespacesAndNewlines),
                overallNote: overallNote.trimmingCharacters(in: .whitespacesAndNewlines),
                flavorTags: cleanTags
            )
            newTasting.bottle = bottle
            bottle.tastings.append(newTasting)
            context.insert(newTasting)
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

private struct LabeledField: View {
    var label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(Brand.text3)
            TextField("Optional", text: $text, axis: .vertical)
                .lineLimit(1...3)
                .accessibilityLabel(label)
        }
        .padding(.vertical, 2)
    }
}
