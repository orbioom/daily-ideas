import SwiftUI
import SwiftData

struct WishlistView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \VisitMark.createdAt, order: .forward) private var marks: [VisitMark]

    @State private var selected: Country?

    private var wishlist: [VisitMark] { marks.filter { $0.status == .wishlist } }

    var body: some View {
        NavigationStack {
            Group {
                if wishlist.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "heart",
                                       title: "Nothing on your list yet",
                                       message: "Browse Explore and set a country to Wishlist to start your bucket list.")
                            .glassCard()
                            .padding(20)
                    }
                } else {
                    List {
                        Section {
                            ForEach(wishlist) { mark in
                                if let country = mark.country {
                                    row(mark: mark, country: country)
                                }
                            }
                            .onDelete(perform: remove)
                        } header: {
                            Text("\(wishlist.count) \(wishlist.count == 1 ? "country" : "countries") on your list")
                        } footer: {
                            Text("Swipe a country to remove it, or tap the plane to mark it visited.")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Wishlist")
            .sheet(item: $selected) { CountryDetailView(country: $0) }
        }
    }

    private func row(mark: VisitMark, country: Country) -> some View {
        HStack(spacing: 12) {
            Button {
                Haptics.tap()
                selected = country
            } label: {
                CountryRow(country: country, status: nil, isFavorite: mark.isFavorite)
            }
            .buttonStyle(.plain)

            Button {
                markVisited(mark)
            } label: {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Brand.magic)
                    .padding(8)
                    .background(Brand.magic.opacity(0.14), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark \(country.name) visited")
        }
        .listRowBackground(Color.clear)
    }

    private func markVisited(_ mark: VisitMark) {
        withAnimation(Brand.ease()) {
            mark.status = .visited
            mark.firstVisitYear = Calendar.current.component(.year, from: .now)
            mark.timesVisited = max(1, mark.timesVisited)
            mark.updatedAt = .now
        }
        try? context.save()
        Haptics.success()
    }

    private func remove(at offsets: IndexSet) {
        for index in offsets where wishlist.indices.contains(index) {
            context.delete(wishlist[index])
        }
        try? context.save()
        Haptics.warning()
    }
}
