import SwiftUI
import SwiftData

struct ShelfView: View {
    @Query(sort: \Bean.createdAt, order: .reverse) private var beans: [Bean]
    @State private var showAdd = false
    @State private var showArchived = false

    private var active: [Bean] { beans.filter { !$0.isArchived } }
    private var archived: [Bean] { beans.filter { $0.isArchived } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if beans.isEmpty {
                    EmptyStateView(symbol: "bag",
                                   title: "Your shelf is empty",
                                   message: "Add a bag of coffee to start tracking its freshness and your brews.",
                                   actionTitle: "Add coffee") { showAdd = true }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(active) { bean in
                                NavigationLink(value: bean) { BeanRow(bean: bean) }
                                    .buttonStyle(.plain)
                            }
                            if !archived.isEmpty {
                                DisclosureGroup(isExpanded: $showArchived) {
                                    VStack(spacing: 12) {
                                        ForEach(archived) { bean in
                                            NavigationLink(value: bean) { BeanRow(bean: bean) }
                                                .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.top, 8)
                                } label: {
                                    Text("Finished bags (\(archived.count))")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Shelf")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add coffee")
                }
            }
            .navigationDestination(for: Bean.self) { BeanDetailView(bean: $0) }
            .sheet(isPresented: $showAdd) { BeanEditView(bean: nil) }
        }
    }
}

struct BeanRow: View {
    let bean: Bean
    private var state: FreshnessState {
        DialInEngine.freshness(daysSinceRoast: bean.daysSinceRoast, espresso: true)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(bean.name).font(.headline).foregroundStyle(Theme.textPrimary).lineLimit(1)
                    if !bean.roaster.isEmpty || !bean.origin.isEmpty {
                        Text([bean.roaster, bean.origin].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.caption).foregroundStyle(Theme.textSecondary).lineLimit(1)
                    }
                }
                Spacer()
                FreshnessBadge(state: state, days: bean.daysSinceRoast)
            }
            HStack(spacing: 12) {
                Label(bean.roastLevel.rawValue, systemImage: "flame").font(.caption2).foregroundStyle(Theme.textSecondary)
                Label("\(bean.brews.count) brews", systemImage: "cup.and.saucer").font(.caption2).foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(Fmt.grams(bean.gramsRemaining)) left").font(.caption2.weight(.medium)).foregroundStyle(Theme.accent)
            }
            ProgressView(value: bean.bagSizeGrams > 0 ? bean.gramsRemaining / bean.bagSizeGrams : 0)
                .tint(Theme.accent)
        }
        .cremaCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(bean.name), \(state.rawValue), \(bean.brews.count) brews")
    }
}
