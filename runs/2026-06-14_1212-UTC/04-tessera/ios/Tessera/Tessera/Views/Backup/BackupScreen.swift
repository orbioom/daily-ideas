import SwiftUI
import SwiftData

/// Backup & overview: account/folder/algorithm stats, a Pro-gated export via
/// ShareLink, and an import-from-text path.
struct BackupScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Account.sortIndex) private var accounts: [Account]
    @Query(sort: \Folder.sortIndex) private var folders: [Folder]

    @State private var computing = false
    @State private var overview: Overview?
    @State private var showImport = false
    @State private var showPaywall = false

    /// Computed snapshot for the overview cards.
    private struct Overview {
        var total: Int
        var totp: Int
        var hotp: Int
        var favorites: Int
        var algoCounts: [(String, Int)]
        var folderCounts: [(String, Int)]
        var unfiled: Int
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Backup")
            .sheet(isPresented: $showImport) {
                ImportTextView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .export)
            }
            .task(id: accountsSignature) { await recompute() }
        }
    }

    /// A cheap signature so the overview recomputes when the data set changes.
    private var accountsSignature: String {
        "\(accounts.count)-\(folders.count)-\(accounts.reduce(0) { $0 + ($1.favorite ? 1 : 0) })"
    }

    @ViewBuilder
    private var content: some View {
        if accounts.isEmpty {
            EmptyStateView(symbol: "externaldrive.badge.questionmark",
                           title: "Nothing to back up yet",
                           message: "Once you've added accounts, you'll see an overview here and be able to export an encrypted-at-rest backup.",
                           actionTitle: "Import from text") {
                showImport = true
            }
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    if computing {
                        ProgressView("Crunching your vault…")
                            .padding(.vertical, 30)
                    } else if let overview {
                        summaryGrid(overview)
                        if !overview.algoCounts.isEmpty {
                            breakdownCard(title: "Algorithms",
                                          symbol: "function",
                                          rows: overview.algoCounts)
                        }
                        if !overview.folderCounts.isEmpty || overview.unfiled > 0 {
                            breakdownCard(title: "Folders",
                                          symbol: "folder",
                                          rows: folderRows(overview))
                        }
                    }
                    exportCard
                    importCard
                }
                .padding(20)
            }
        }
    }

    // MARK: Cards

    private func summaryGrid(_ o: Overview) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Accounts", "\(o.total)", "shield.lefthalf.filled", Theme.accent)
            statCard("Favorites", "\(o.favorites)", "star.fill", Theme.warn)
            statCard("Time-based", "\(o.totp)", "clock", Theme.good)
            statCard("Counter", "\(o.hotp)", "number", Theme.inkSoft)
        }
    }

    private func statCard(_ title: String, _ value: String, _ symbol: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            Text(title)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    private func breakdownCard(title: String, symbol: String, rows: [(String, Int)]) -> some View {
        let maxCount = max(rows.map { $0.1 }.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.ink)
            ForEach(rows, id: \.0) { row in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(row.0)
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                        Spacer()
                        Text("\(row.1)")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.ink)
                            .monospacedDigit()
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.surfaceAlt)
                            Capsule().fill(Theme.accent)
                                .frame(width: geo.size.width * CGFloat(row.1) / CGFloat(maxCount))
                        }
                    }
                    .frame(height: 7)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(row.0): \(row.1)")
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Export backup", systemImage: "square.and.arrow.up")
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.ink)
            Text("Save all \(accounts.count) account\(accounts.count == 1 ? "" : "s") as standard otpauth:// lines you can re-import anywhere. Keep the file private.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            if isPro {
                ShareLink(item: BackupText.export(accounts: accounts),
                          preview: SharePreview("Tessera backup")) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export otpauth backup")
                    }
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accent))
                }
                ShareLink(item: BackupText.plainList(accounts: accounts),
                          preview: SharePreview("Tessera account list")) {
                    Text("Export readable list")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.accent)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                        Text("Export is a Pro feature")
                    }
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accent))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private var importCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Import from text", systemImage: "square.and.arrow.down")
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.ink)
            Text("Paste otpauth:// lines exported from Tessera or another app. Invalid lines are skipped.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                showImport = true
            } label: {
                Text("Import accounts")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accentSoft))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    // MARK: Compute

    private func folderRows(_ o: Overview) -> [(String, Int)] {
        var rows = o.folderCounts
        if o.unfiled > 0 { rows.append(("Unfiled", o.unfiled)) }
        return rows
    }

    @MainActor
    private func recompute() async {
        computing = true
        // Tiny yield so the spinner is visible on large vaults.
        try? await Task.sleep(nanoseconds: 200_000_000)

        var algo: [String: Int] = [:]
        var totp = 0, hotp = 0, favorites = 0
        for a in accounts {
            algo[a.algorithm.displayName, default: 0] += 1
            if a.type == .totp { totp += 1 } else { hotp += 1 }
            if a.favorite { favorites += 1 }
        }
        let algoCounts = algo.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }

        var folderCounts: [(String, Int)] = []
        for f in folders { folderCounts.append((f.name, f.accounts.count)) }
        let unfiled = accounts.filter { $0.folder == nil }.count

        overview = Overview(total: accounts.count,
                            totp: totp, hotp: hotp, favorites: favorites,
                            algoCounts: algoCounts,
                            folderCounts: folderCounts,
                            unfiled: unfiled)
        computing = false
    }
}
