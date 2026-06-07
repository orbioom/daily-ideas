import SwiftUI
import SwiftData

/// A searchable catalog picker with an inline "add a new species" form for birds
/// not yet in the catalog.
struct SpeciesPickerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Species.taxonOrder) private var species: [Species]
    @Binding var selection: Species?
    @State private var search = ""
    @State private var showingAdd = false

    private var filtered: [Species] {
        guard !search.isEmpty else { return species }
        let q = search.lowercased()
        return species.filter { $0.commonName.lowercased().contains(q) || $0.scientificName.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            List {
                if filtered.isEmpty {
                    Text("No matches — add a new species below.")
                        .foregroundStyle(Brand.text3).listRowBackground(Color.clear)
                }
                ForEach(filtered) { sp in
                    Button {
                        selection = sp; Haptics.selection(); dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(sp.commonName).foregroundStyle(Brand.text)
                                Text(sp.scientificName).font(.caption).italic().foregroundStyle(Brand.text3)
                            }
                            Spacer()
                            if selection?.id == sp.id {
                                Image(systemName: "checkmark").foregroundStyle(Brand.live)
                            }
                            if sp.isCustom { Badge(text: "Custom") }
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .searchable(text: $search, prompt: "Search or type a new name")
            .navigationTitle("Choose Species")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add new species")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddSpeciesView(prefillName: search) { newSpecies in
                    selection = newSpecies; dismiss()
                }
            }
        }
    }
}

struct AddSpeciesView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Species.taxonOrder, order: .reverse) private var species: [Species]
    let prefillName: String
    var onCreate: (Species) -> Void

    @State private var common = ""
    @State private var scientific = ""
    @State private var family = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Common name", text: $common).font(.headline).foregroundStyle(Brand.text)
                        Divider().overlay(Brand.hairline)
                        TextField("Scientific name (optional)", text: $scientific)
                            .italic().foregroundStyle(Brand.text2)
                        Divider().overlay(Brand.hairline)
                        TextField("Family (optional)", text: $family).foregroundStyle(Brand.text2)
                    }
                    .glassCard()
                    Text("Custom species are added to the end of your checklist order.")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                .padding()
            }
            .navigationTitle("New Species")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { create() }
                        .disabled(common.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { if common.isEmpty { common = prefillName } }
        }
    }

    private func create() {
        let name = common.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let nextOrder = (species.first?.taxonOrder ?? 0) + 1000
        let sp = Species(commonName: name,
                         scientificName: scientific.trimmingCharacters(in: .whitespaces),
                         family: family.trimmingCharacters(in: .whitespaces).isEmpty ? "Other" : family,
                         taxonOrder: nextOrder, isCustom: true)
        context.insert(sp)
        try? context.save()
        Haptics.success()
        onCreate(sp)
        dismiss()
    }
}
