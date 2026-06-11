import SwiftUI
import SwiftData

struct MilestonesView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @AppStorage("retirementAge") private var retirementAge = 65.0
    @Query private var profiles: [Profile]
    @Query(sort: \Milestone.targetAmount) private var customMilestones: [Milestone]
    @State private var showAdd = false
    @State private var newTitle = ""
    @State private var newAmount = ""
    @State private var addError: String?

    private var profile: Profile? { profiles.first }

    private struct Row: Identifiable {
        let id: String
        let title: String
        let emoji: String
        let amount: Double
        let reached: Bool
        let custom: Milestone?
    }

    private var rows: [Row] {
        guard let profile else { return [] }
        let coast = FIEngine.coastFINumber(profile: profile, retirementAge: retirementAge)
        var result: [Row] = FIEngine.autoMilestones(fiNumber: profile.fiNumber, coastNumber: coast)
            .map { Row(id: "auto-\($0.title)", title: $0.title, emoji: $0.emoji,
                       amount: $0.amount, reached: profile.currentInvested >= $0.amount, custom: nil) }
        for m in customMilestones {
            result.append(Row(id: "custom-\(m.persistentModelID)", title: m.title, emoji: m.emoji,
                              amount: m.targetAmount,
                              reached: profile.currentInvested >= m.targetAmount, custom: m))
        }
        return result.sorted { $0.amount < $1.amount }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    List {
                        Section {
                            ForEach(rows) { row in
                                milestoneRow(row, profile: profile)
                            }
                            .onDelete(perform: deleteCustom)
                        } header: {
                            let reached = rows.filter(\.reached).count
                            Text("\(reached) of \(rows.count) reached")
                        } footer: {
                            Text("Coast FI and the FI fractions are calculated for you. Add your own targets — a house deposit, a sabbatical fund — below.")
                        }
                        Section {
                            Button {
                                showAdd = true
                            } label: {
                                Label("Add custom milestone", systemImage: "plus.circle.fill")
                                    .foregroundStyle(Theme.teal)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                } else {
                    EmptyStateView(icon: "flag.checkered",
                                   title: "No plan yet",
                                   message: "Set up your plan to see your milestones.")
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Milestones")
            .alert("New milestone", isPresented: $showAdd) {
                TextField("Name (e.g. House deposit)", text: $newTitle)
                TextField("Target amount", text: $newAmount)
                    .keyboardType(.decimalPad)
                Button("Add") { addMilestone() }
                Button("Cancel", role: .cancel) { newTitle = ""; newAmount = "" }
            } message: {
                Text("Track any savings goal alongside your FI journey.")
            }
            .alert("Couldn't add", isPresented: Binding(
                get: { addError != nil }, set: { if !$0 { addError = nil } })) {
                Button("OK", role: .cancel) { addError = nil }
            } message: {
                Text(addError ?? "")
            }
        }
    }

    private func milestoneRow(_ row: Row, profile: Profile) -> some View {
        let progress = row.amount > 0 ? min(profile.currentInvested / row.amount, 1) : 0
        return HStack(spacing: 14) {
            Text(row.emoji)
                .font(.title2)
                .frame(width: 36)
                .grayscale(row.reached ? 0 : 0.6)
                .opacity(row.reached ? 1 : 0.7)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(row.title)
                        .font(.subheadline.weight(.semibold))
                        .strikethrough(row.reached, color: Theme.inkSoft(scheme))
                        .foregroundStyle(Theme.ink(scheme))
                    if row.custom != nil {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.inkSoft(scheme))
                            .accessibilityLabel("Custom milestone")
                    }
                }
                Text(FIEngine.money(row.amount, code: profile.currencyCode))
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft(scheme))
                if !row.reached {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.inkSoft(scheme).opacity(0.15))
                            Capsule().fill(Theme.teal)
                                .frame(width: max(geo.size.width * progress, 4))
                        }
                    }
                    .frame(height: 6)
                }
            }
            Spacer()
            if row.reached {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Theme.teal)
            } else {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.inkSoft(scheme))
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.title), \(FIEngine.money(row.amount, code: profile.currencyCode)), \(row.reached ? "reached" : "\(Int((progress * 100).rounded())) percent")")
    }

    private func deleteCustom(at offsets: IndexSet) {
        for index in offsets {
            if let custom = rows[index].custom {
                context.delete(custom)
            }
        }
    }

    private func addMilestone() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = newAmount.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
        defer { newTitle = ""; newAmount = "" }
        guard !title.isEmpty else {
            addError = "Give the milestone a name."
            return
        }
        guard let amount = Double(cleaned), amount > 0, amount < 1_000_000_000 else {
            addError = "Enter a target amount above zero."
            return
        }
        context.insert(Milestone(title: title, targetAmount: amount, isAuto: false, emoji: "🎯"))
        Haptics.success()
    }
}
