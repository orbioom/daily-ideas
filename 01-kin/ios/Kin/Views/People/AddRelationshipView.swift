import SwiftUI
import SwiftData

struct AddRelationshipView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.lastName) private var allPeople: [Person]

    let person: Person

    @State private var relType: RelationshipType = .parentChild
    @State private var selectedPerson: Person?
    @State private var search = ""

    var filteredPeople: [Person] {
        let others = allPeople.filter { $0.id != person.id }
        if search.isEmpty { return others }
        return others.filter { $0.fullName.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Relationship Type") {
                    Picker("Type", selection: $relType) {
                        ForEach(RelationshipType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Relationship type")
                }
                Section("Select Person") {
                    if filteredPeople.isEmpty {
                        Text("No other people in your tree.")
                            .foregroundColor(KinTheme.secondaryLabel)
                            .font(Font.kinBody)
                    } else {
                        ForEach(filteredPeople) { p in
                            Button(action: { selectedPerson = p }) {
                                HStack {
                                    PersonAvatarView(person: p, size: 36)
                                    Text(p.fullName)
                                        .font(Font.kinBody)
                                        .foregroundColor(KinTheme.label)
                                    Spacer()
                                    if selectedPerson?.id == p.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(KinTheme.accent)
                                    }
                                }
                            }
                            .accessibilityLabel("\(p.fullName), \(selectedPerson?.id == p.id ? "selected" : "not selected")")
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search people")
            .navigationTitle("Add Relationship")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(selectedPerson == nil)
                }
            }
        }
    }

    private func save() {
        guard let target = selectedPerson else { return }
        let rel = Relationship(type: relType, person1: person, person2: target)
        context.insert(rel)
        try? context.save()
        dismiss()
    }
}
