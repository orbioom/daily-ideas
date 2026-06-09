import SwiftUI
import SwiftData

struct PeopleView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Person.sortIndex) private var people: [Person]
    @AppStorage("trove.currencyCode") private var currencyCode = "USD"

    @State private var showAdd = false

    var body: some View {
        ScrollView {
            if people.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: "No people yet",
                    message: "Add the people you give to — family, friends, partners, colleagues. Tap + to start.")
                .glassCard()
                .padding(20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(people) { person in
                        NavigationLink {
                            PersonDetailView(person: person)
                        } label: {
                            PersonRow(person: person, currencyCode: currencyCode)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("People")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add person")
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack { PersonEditorView() }
        }
    }
}

private struct PersonRow: View {
    let person: Person
    let currencyCode: String

    private var giftCount: Int { person.gifts.count }
    private var spend: Double { GiftEngine.spend(for: person) }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: (Relation(rawValue: person.relation) ?? .other).symbol)
                .font(.system(size: 18))
                .foregroundStyle(Brand.info)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(person.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Brand.text)
                Text("\(person.relation) · \(giftCount) gift\(giftCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
            }
            Spacer()
            if spend > 0 {
                Text(Format.currency(spend, code: currencyCode))
                    .font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(Brand.text)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(person.name), \(person.relation), \(giftCount) gifts"
            + (spend > 0 ? ", \(Format.currency(spend, code: currencyCode)) spent" : ""))
    }
}
