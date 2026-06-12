import SwiftUI
import SwiftData

struct BrewLogView: View {
    @Query(sort: \Bean.createdAt) private var beans: [Bean]
    @State private var methodFilter: BrewMethod? = nil
    @State private var showAdd = false

    private var allBrews: [Brew] {
        var list = beans.flatMap(\.brews)
        if let methodFilter { list = list.filter { $0.method == methodFilter } }
        return list.sorted { $0.date > $1.date }
    }
    private var hasAnyBrews: Bool { beans.contains { !$0.brews.isEmpty } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if beans.isEmpty {
                    EmptyStateView(symbol: "cup.and.saucer",
                                   title: "No brews yet",
                                   message: "Add a coffee to your shelf, then log your first brew to start your record.")
                } else if !hasAnyBrews {
                    EmptyStateView(symbol: "cup.and.saucer",
                                   title: "No brews logged",
                                   message: "Log a brew and it will appear here across all your beans.",
                                   actionTitle: "Log a brew") { showAdd = true }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            filterBar
                            if allBrews.isEmpty {
                                Text("No \(methodFilter?.rawValue ?? "") brews yet.")
                                    .font(.subheadline).foregroundStyle(Theme.textSecondary).padding(.top, 30)
                            } else {
                                ForEach(allBrews) { brew in
                                    NavigationLink(value: brew) { BrewRow(brew: brew, showBean: true) }
                                        .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Brews")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log brew")
                        .disabled(beans.isEmpty)
                }
            }
            .navigationDestination(for: Brew.self) { BrewDetailView(brew: $0) }
            .sheet(isPresented: $showAdd) { BrewEditView(brew: nil, preselectedBean: beans.first { !$0.isArchived }) }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", nil)
                ForEach(BrewMethod.allCases) { m in
                    if beans.flatMap(\.brews).contains(where: { $0.method == m }) { chip(m.rawValue, m) }
                }
            }
        }
    }

    private func chip(_ title: String, _ method: BrewMethod?) -> some View {
        Button {
            Haptics.tap(); methodFilter = method
        } label: {
            Text(title).font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(methodFilter == method ? Theme.accent : Theme.bgElevated, in: Capsule())
                .foregroundStyle(methodFilter == method ? .white : Theme.textPrimary)
        }
        .accessibilityAddTraits(methodFilter == method ? [.isSelected] : [])
    }
}

struct BrewRow: View {
    let brew: Brew
    var showBean: Bool
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.accent.opacity(0.14)).frame(width: 44, height: 44)
                Image(systemName: brew.method.symbol).foregroundStyle(Theme.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if showBean, let name = brew.bean?.name {
                        Text(name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary).lineLimit(1)
                    } else {
                        Text(brew.method.rawValue).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                    }
                    if let taste = brew.taste {
                        Image(systemName: taste.symbol).font(.caption2).foregroundStyle(taste.color)
                    }
                }
                Text("\(Fmt.grams(brew.doseGrams)) → \(Fmt.grams(brew.outputGrams)) · \(brew.ratioString) · \(Int(brew.timeSeconds))s")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                if brew.ratingHalf > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill").font(.caption2).foregroundStyle(Theme.crema)
                        Text(String(format: "%.1f", brew.rating)).font(.caption.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                    }
                }
                Text(Fmt.relativeDay(brew.date)).font(.caption2).foregroundStyle(Theme.textSecondary)
            }
        }
        .cremaCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(brew.bean?.name ?? brew.method.rawValue), ratio \(brew.ratioString)")
    }
}
