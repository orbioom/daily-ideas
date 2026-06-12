import SwiftUI
import SwiftData

struct BeanDetailView: View {
    @Bindable var bean: Bean
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    @State private var showAddBrew = false
    @State private var showDelete = false

    private var espressoFresh: FreshnessState {
        DialInEngine.freshness(daysSinceRoast: bean.daysSinceRoast, espresso: true)
    }
    private var sortedBrews: [Brew] { bean.brews.sorted { $0.date > $1.date } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                freshnessCard
                if !bean.notes.isEmpty { notesCard }
                if let best = bean.bestBrew { bestCard(best) }
                brewsCard
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Theme.bgPrimary.ignoresSafeArea())
        .navigationTitle(bean.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button {
                        bean.isArchived.toggle(); try? context.save()
                    } label: { Label(bean.isArchived ? "Mark as open" : "Mark as finished",
                                     systemImage: bean.isArchived ? "bag" : "bag.badge.minus") }
                    Button(role: .destructive) { showDelete = true } label: { Label("Delete", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .navigationDestination(for: Brew.self) { BrewDetailView(brew: $0) }
        .sheet(isPresented: $showEdit) { BeanEditView(bean: bean) }
        .sheet(isPresented: $showAddBrew) { BrewEditView(brew: nil, preselectedBean: bean) }
        .confirmationDialog("Delete \(bean.name) and its brews?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { context.delete(bean); try? context.save(); dismiss() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var freshnessCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text([bean.roaster, bean.origin].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.subheadline).foregroundStyle(Theme.textSecondary)
                    HStack(spacing: 8) {
                        Label(bean.roastLevel.rawValue, systemImage: "flame.fill").font(.caption).foregroundStyle(Theme.accent)
                        Label(bean.process.rawValue, systemImage: "drop.fill").font(.caption).foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                FreshnessBadge(state: espressoFresh, days: bean.daysSinceRoast)
            }
            Divider().overlay(Theme.track)
            Text(espressoFresh.advice).font(.callout).foregroundStyle(Theme.textPrimary)
            HStack {
                stat("\(Fmt.grams(bean.gramsRemaining))", "remaining")
                Divider().frame(height: 30).overlay(Theme.track)
                stat("\(bean.brews.count)", "brews")
                if bean.roastDate != nil {
                    Divider().frame(height: 30).overlay(Theme.track)
                    stat(bean.daysSinceRoast.map { "\($0)d" } ?? "—", "off roast")
                }
            }
            Button { Haptics.tap(); showAddBrew = true } label: {
                Label("Log a brew", systemImage: "plus.circle.fill").font(.headline).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(Theme.accent).controlSize(.large)
        }
        .cremaCard()
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).foregroundStyle(Theme.textPrimary)
            Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            Text(bean.notes).font(.body).foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cremaCard()
    }

    private func bestCard(_ brew: Brew) -> some View {
        NavigationLink(value: brew) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Best recipe so far", systemImage: "trophy.fill")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.crema)
                HStack {
                    MethodPill(method: brew.method)
                    Text("\(Fmt.grams(brew.doseGrams)) → \(Fmt.grams(brew.outputGrams))")
                        .font(.subheadline).foregroundStyle(Theme.textPrimary)
                    Text(brew.ratioString).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accent)
                    Spacer()
                    Text("\(Int(brew.timeSeconds))s").font(.subheadline).foregroundStyle(Theme.textSecondary)
                }
                if !brew.grindSetting.isEmpty {
                    Text("Grind \(brew.grindSetting)").font(.caption).foregroundStyle(Theme.textSecondary)
                }
            }
            .cremaCard()
        }
        .buttonStyle(.plain)
    }

    private var brewsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Brew history").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            if sortedBrews.isEmpty {
                Text("No brews logged for this bag yet. Tap Log a brew above.")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(sortedBrews) { brew in
                    NavigationLink(value: brew) { BrewRow(brew: brew, showBean: false) }
                        .buttonStyle(.plain)
                }
            }
        }
        .cremaCard()
    }
}
