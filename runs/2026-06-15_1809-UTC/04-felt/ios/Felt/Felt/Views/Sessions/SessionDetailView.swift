import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Bindable var session: Session

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    private var sym: String { settings.currencySymbol }
    private var hide: Bool { settings.hideAmounts }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                resultCard
                detailsCard
                if session.format == .tournament { tournamentCard }
                if !session.notes.isEmpty || !session.tag.isEmpty { notesCard }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap(enabled: settings.hapticsEnabled)
                    showEdit = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            AddEditSessionView(session: session)
        }
    }

    private var resultCard: some View {
        VStack(spacing: 10) {
            Image(systemName: session.format.symbol)
                .font(.system(size: 30))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            Text(session.profit >= 0 ? "Profit" : "Loss")
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(.white.opacity(0.85))
            Text(hide ? "\(sym)••••" : Money.string(session.profit, symbol: sym, signed: true))
                .font(Theme.mono(38, .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(Self.dateFormatter.string(from: session.date))
                .font(Theme.rounded(13))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Theme.heroGradient)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Result \(hide ? "hidden" : Money.string(session.profit, symbol: sym, signed: true))")
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow("Format", session.format.rawValue)
            divider
            detailRow("Game", session.gameType.fullName)
            divider
            detailRow("Location", session.location.isEmpty ? "—" : session.location)
            divider
            detailRow("Stakes", session.stakes.isEmpty ? "—" : session.stakes)
            divider
            detailRow("Duration", DurationFormat.string(minutes: session.durationMinutes))
            divider
            moneyRow("Buy-in", session.buyIn)
            divider
            moneyRow("Cash-out", session.cashOut)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .cardSurface()
    }

    private var tournamentCard: some View {
        VStack(spacing: 0) {
            detailRow("Entries", session.tournamentEntries.map(String.init) ?? "—")
            divider
            detailRow("Your place", session.tournamentPlace.map { "#\($0)" } ?? "—")
            divider
            detailRow("ROI", roiString)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .cardSurface()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !session.tag.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill").font(.system(size: 12)).foregroundStyle(Theme.accent)
                    Text(session.tag).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
                }
            }
            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface()
    }

    private var roiString: String {
        guard session.buyIn > 0 else { return "—" }
        let roi = NSDecimalNumber(decimal: session.profit / session.buyIn).doubleValue * 100
        return Money.percent(roi.isFinite ? roi : 0)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private func moneyRow(_ label: String, _ value: Decimal) -> some View {
        HStack {
            Text(label).font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
            Spacer()
            MoneyText(value: value, symbol: sym, size: 15, colored: false, hidden: hide)
        }
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Divider().overlay(Theme.hairline)
    }
}
