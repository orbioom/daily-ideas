import SwiftUI
import SwiftData

/// Add or edit a single gift. When `gift` is nil this creates a new one,
/// optionally pre-linked to a person and/or occasion.
struct GiftEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("trove.currencyCode") private var currencyCode = "USD"

    @Query(sort: \Person.sortIndex) private var people: [Person]
    @Query(sort: \Occasion.sortIndex) private var occasions: [Occasion]

    /// The gift being edited, or nil to create a new one.
    var gift: Gift?
    var presetPerson: Person?
    var presetOccasion: Occasion?

    @State private var title = ""
    @State private var priceText = ""
    @State private var status: GiftStatus = .idea
    @State private var store = ""
    @State private var link = ""
    @State private var notes = ""
    @State private var personID: PersistentIdentifier?
    @State private var occasionID: PersistentIdentifier?
    @State private var showDeleteConfirm = false

    private var isEditing: Bool { gift != nil }
    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedTitle.isEmpty }

    var body: some View {
        Form {
            Section("Gift") {
                TextField("Title", text: $title)
                    .accessibilityLabel("Gift title")
                HStack {
                    Text(Format.symbol(for: currencyCode))
                        .foregroundStyle(Brand.text3)
                    TextField("Price", text: $priceText)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Price")
                }
                Picker("Status", selection: $status) {
                    ForEach(GiftStatus.allCases) { s in
                        Label(s.label, systemImage: s.symbol).tag(s)
                    }
                }
            }

            Section("Links") {
                Picker("Person", selection: $personID) {
                    Text("None").tag(PersistentIdentifier?.none)
                    ForEach(people) { p in
                        Text(p.name).tag(Optional(p.persistentModelID))
                    }
                }
                Picker("Occasion", selection: $occasionID) {
                    Text("None").tag(PersistentIdentifier?.none)
                    ForEach(occasions) { o in
                        Text(o.name).tag(Optional(o.persistentModelID))
                    }
                }
            }

            Section("Details") {
                TextField("Store", text: $store)
                    .textInputAutocapitalization(.words)
                TextField("Link", text: $link)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }

            if isEditing {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete gift", systemImage: "trash")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(isEditing ? "Edit Gift" : "New Gift")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!canSave)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .confirmationDialog("Delete this gift?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteGift() }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear(perform: load)
    }

    private func load() {
        if let gift {
            title = gift.title
            priceText = gift.price > 0 ? trimmedNumber(gift.price) : ""
            status = gift.status
            store = gift.store
            link = gift.link
            notes = gift.notes
            personID = gift.person?.persistentModelID
            occasionID = gift.occasion?.persistentModelID
        } else {
            personID = presetPerson?.persistentModelID
            occasionID = presetOccasion?.persistentModelID
        }
    }

    private func trimmedNumber(_ value: Double) -> String {
        if value == value.rounded() { return String(format: "%.0f", value) }
        return String(format: "%.2f", value)
    }

    private func parsedPrice() -> Double {
        let cleaned = priceText.replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        return max(0, Double(cleaned) ?? 0)
    }

    private func resolvedPerson() -> Person? {
        guard let id = personID else { return nil }
        return people.first { $0.persistentModelID == id }
    }

    private func resolvedOccasion() -> Occasion? {
        guard let id = occasionID else { return nil }
        return occasions.first { $0.persistentModelID == id }
    }

    private func save() {
        guard canSave else { return }
        let target = gift ?? Gift(title: trimmedTitle)
        target.title = trimmedTitle
        target.price = parsedPrice()
        target.status = status
        target.store = store.trimmingCharacters(in: .whitespacesAndNewlines)
        target.link = link.trimmingCharacters(in: .whitespacesAndNewlines)
        target.notes = notes
        target.person = resolvedPerson()
        target.occasion = resolvedOccasion()
        if gift == nil { context.insert(target) }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func deleteGift() {
        guard let gift else { return }
        context.delete(gift)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}
