import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var person: Person

    @AppStorage("trove.currencyCode") private var currencyCode = "USD"
    @AppStorage("trove.showGiven") private var showGiven = true

    @State private var showEdit = false
    @State private var showAddGift = false
    @State private var showDeleteConfirm = false

    private var nextBirthday: Date? { GiftEngine.nextBirthday(for: person) }
    private var spend: Double { GiftEngine.spend(for: person) }

    /// Gifts visible given the show-given preference, grouped by status order.
    private var groupedGifts: [(status: GiftStatus, gifts: [Gift])] {
        let visible = person.gifts.filter { showGiven || $0.status != .given }
        return GiftStatus.allCases.compactMap { status in
            let g = visible.filter { $0.status == status }
                .sorted { $0.createdAt > $1.createdAt }
            return g.isEmpty ? nil : (status, g)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let nextBirthday {
                    InfoCard(icon: "birthday.cake",
                             title: "Next birthday",
                             value: "\(Format.shortDay.string(from: nextBirthday)) · \(Format.countdown(daysAway: GiftEngine.daysAway(nextBirthday)))",
                             tint: Brand.magic)
                }
                if !person.sizesNote.isEmpty {
                    InfoCard(icon: "ruler", title: "Sizes", value: person.sizesNote, tint: Brand.info)
                }
                if !person.notes.isEmpty {
                    InfoCard(icon: "note.text", title: "Notes", value: person.notes, tint: Brand.text2)
                }
                giftsSection
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit person", systemImage: "pencil") }
                    Button { showAddGift = true } label: { Label("Add gift", systemImage: "gift") }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete person", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Person options")
            }
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack { PersonEditorView(person: person) }
        }
        .sheet(isPresented: $showAddGift) {
            NavigationStack { GiftEditorView(presetPerson: person) }
        }
        .confirmationDialog("Delete \(person.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deletePerson() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This also deletes their \(person.gifts.count) gift\(person.gifts.count == 1 ? "" : "s"). This can't be undone.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(person.gifts.count)", label: "Gifts")
            StatTile(value: "\(GiftEngine.toBuyCount(person.gifts))", label: "To buy", tint: Brand.info)
            StatTile(value: Format.currency(spend, code: currencyCode), label: "Spent")
        }
    }

    private var giftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Gifts")
                Spacer()
                Button {
                    Haptics.tap()
                    showAddGift = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline.weight(.medium))
                }
            }
            if groupedGifts.isEmpty {
                Text("No gift ideas yet. Add one to start planning.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .glassCard()
            } else {
                ForEach(groupedGifts, id: \.status) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.status.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(group.status.color)
                        VStack(spacing: 10) {
                            ForEach(group.gifts) { gift in
                                NavigationLink {
                                    GiftEditorView(gift: gift)
                                } label: {
                                    GiftRow(gift: gift, showOccasion: true, currencyCode: currencyCode)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .glassCard(padding: 14)
                    }
                }
            }
        }
    }

    private func deletePerson() {
        context.delete(person)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}

/// A simple labeled glass card with a leading icon.
struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    var tint: Color = Brand.text2

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(tint)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(Brand.mono(11, weight: .medium))
                    .tracking(1.0)
                    .foregroundStyle(Brand.text3)
                Text(value)
                    .font(.body)
                    .foregroundStyle(Brand.text)
            }
            Spacer()
        }
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
