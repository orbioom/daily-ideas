import SwiftUI
import SwiftData
import Charts

struct KidDetailView: View {
    @Bindable var kid: Kid
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("sprout.symbol") private var symbol = "$"

    @State private var editing = false
    @State private var ledgerSheet = false
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                balanceCard
                actionRow
                pointsCard
                ledgerCard
                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Remove child", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle()).tint(Brand.danger)
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(kid.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Edit") { editing = true } }
        }
        .sheet(isPresented: $editing) { KidEditorView(kid: kid, nextIndex: kid.sortIndex) }
        .sheet(isPresented: $ledgerSheet) { LedgerSheet(kid: kid) }
        .alert("Remove \(kid.name)?", isPresented: $confirmDelete) {
            Button("Remove", role: .destructive) { context.delete(kid); try? context.save(); dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This removes the child and all their chores, history and balance.") }
    }

    private var balanceCard: some View {
        GlassCard {
            VStack(spacing: 8) {
                KidAvatar(kid: kid, size: 64)
                Text(Money.string(kid.balance, symbol: symbol))
                    .font(Brand.mono(34, weight: .bold))
                    .foregroundStyle(kid.balance >= 0 ? Brand.text : Brand.danger)
                Text("Current balance").font(.caption).foregroundStyle(Brand.text3)
                HStack(spacing: 22) {
                    stat("Points", "\(kid.totalPoints)")
                    stat("This week", Money.string(ChoreEngine.earnedThisWeek(for: kid), symbol: symbol))
                    stat("Done", "\(ChoreEngine.completionsThisWeek(for: kid))")
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
            Text(label).font(.caption2).foregroundStyle(Brand.text3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button { Haptics.tap(); ledgerSheet = true } label: {
                Label("Money", systemImage: "plusminus.circle.fill")
            }
            .buttonStyle(GlassButtonStyle())
            if kid.weeklyAllowance > 0 {
                Button {
                    Haptics.success()
                    let e = LedgerEntry(amount: kid.weeklyAllowance, kind: .allowance, note: "Allowance")
                    e.kid = kid
                    kid.lastAllowancePaid = .now
                    context.insert(e); try? context.save()
                } label: { Label("Pay allowance", systemImage: "calendar.badge.clock") }
                .buttonStyle(GlassButtonStyle())
            }
        }
    }

    private var pointsCard: some View {
        let data = ChoreEngine.dailyPoints(for: kid, days: 14)
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Points · last 14 days")
                if data.allSatisfy({ $0.points == 0 }) {
                    Text("Completed chores will appear here.").font(.subheadline).foregroundStyle(Brand.text3)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                } else {
                    Chart(data) { d in
                        BarMark(x: .value("Day", d.day, unit: .day), y: .value("Points", d.points))
                            .foregroundStyle(kid.color.color).cornerRadius(4)
                    }
                    .frame(height: 160)
                    .chartXAxis { AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }
                    .accessibilityLabel("Points earned per day over the last 14 days")
                }
            }
        }
    }

    private var ledgerCard: some View {
        let entries = (kid.ledger.map { LedgerRow(date: $0.date, title: $0.kind.title, note: $0.note,
                                                  amount: $0.amount, icon: $0.kind.icon, entry: $0, completion: nil) }
                       + kid.completions.filter { $0.approved && $0.reward > 0 }.map {
                           LedgerRow(date: $0.date, title: "Chore reward", note: $0.choreTitle,
                                     amount: $0.reward, icon: "checkmark.circle.fill", entry: nil, completion: $0) })
            .sorted { $0.date > $1.date }
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Money history")
                if entries.isEmpty {
                    Text("No money movements yet. Complete a paid chore or add a bonus.")
                        .font(.subheadline).foregroundStyle(Brand.text3)
                } else {
                    ForEach(entries.prefix(20)) { row in
                        HStack(spacing: 10) {
                            Image(systemName: row.icon)
                                .foregroundStyle(row.amount >= 0 ? Brand.live : Brand.danger)
                                .frame(width: 24).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(row.title).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                Text(row.note.isEmpty ? Format.relativeDay(row.date) : "\(row.note) · \(Format.relativeDay(row.date))")
                                    .font(.caption).foregroundStyle(Brand.text3)
                            }
                            Spacer()
                            Text(Money.string(row.amount, symbol: symbol, showsSign: true))
                                .font(Brand.mono(14)).foregroundStyle(row.amount >= 0 ? Brand.text : Brand.danger)
                            if let entry = row.entry {
                                Button { context.delete(entry); try? context.save() } label: {
                                    Image(systemName: "trash").font(.caption).foregroundStyle(Brand.danger)
                                }
                                .buttonStyle(.plain).accessibilityLabel("Delete entry")
                            }
                        }
                        .padding(.vertical, 3)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private struct LedgerRow: Identifiable {
        let id = UUID()
        let date: Date
        let title: String
        let note: String
        let amount: Double
        let icon: String
        let entry: LedgerEntry?
        let completion: Completion?
    }
}
