import SwiftUI
import SwiftData

struct PeopleListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Person.lastName) private var people: [Person]

    @State private var search = ""
    @State private var showAdd = false
    @State private var selectedPerson: Person?

    var filtered: [Person] {
        if search.isEmpty { return people }
        return people.filter {
            $0.fullName.localizedCaseInsensitiveContains(search) ||
            $0.birthPlace.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if people.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filtered) { person in
                            NavigationLink(value: person) {
                                PersonRowView(person: person)
                            }
                        }
                        .onDelete(perform: deletePeople)
                    }
                    .listStyle(.plain)
                    .searchable(text: $search, prompt: "Search by name or birthplace")
                }
            }
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Person.self) { person in
                PersonDetailView(person: person)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                    .accessibilityLabel("Add person")
                }
            }
            .sheet(isPresented: $showAdd) {
                AddEditPersonView(person: nil)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 56))
                .foregroundColor(KinTheme.sepia)
                .accessibilityHidden(true)
            Text("No People Yet")
                .font(Font.kinHeadline)
                .foregroundColor(KinTheme.label)
            Text("Add family members to start\nbuilding your tree.")
                .font(Font.kinBody)
                .foregroundColor(KinTheme.secondaryLabel)
                .multilineTextAlignment(.center)
            Button("Add First Person") { showAdd = true }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Add first person")
        }
        .padding()
    }

    private func deletePeople(at offsets: IndexSet) {
        for index in offsets {
            let person = filtered[index]
            if let filename = person.photoFilename {
                PhotoStore.shared.delete(filename: filename)
            }
            context.delete(person)
        }
        try? context.save()
    }
}

struct PersonRowView: View {
    let person: Person

    var body: some View {
        HStack(spacing: 12) {
            PersonAvatarView(person: person, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(person.fullName)
                        .font(Font.kinHeadline)
                        .foregroundColor(KinTheme.label)
                    if person.isDeceased {
                        Image(systemName: "moon.fill")
                            .font(.caption)
                            .foregroundColor(KinTheme.secondaryLabel)
                            .accessibilityLabel("Deceased")
                    }
                }
                Group {
                    if let age = person.age {
                        Text(person.isDeceased ? "Lived \(age) years" : "Age \(age)")
                            .font(Font.kinCaption)
                            .foregroundColor(KinTheme.secondaryLabel)
                    } else if !person.birthPlace.isEmpty {
                        Text(person.birthPlace)
                            .font(Font.kinCaption)
                            .foregroundColor(KinTheme.secondaryLabel)
                    } else {
                        Text("No dates recorded")
                            .font(Font.kinCaption)
                            .foregroundColor(KinTheme.secondaryLabel)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(person.fullName)\(person.isDeceased ? ", deceased" : "")")
    }
}
