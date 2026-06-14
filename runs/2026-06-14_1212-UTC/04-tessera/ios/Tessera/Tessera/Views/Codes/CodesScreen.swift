import SwiftUI
import SwiftData
import UIKit

/// The main screen: live list of OTP codes with search, folder filter, copy, and
/// favorites. A single TimelineView drives the per-second refresh for all rows.
struct CodesScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("didSeed") private var didSeed = false

    @Query(sort: \Account.sortIndex) private var accounts: [Account]
    @Query(sort: \Folder.sortIndex) private var folders: [Folder]

    @State private var searchText = ""
    @State private var selectedFolderID: UUID? = nil
    @State private var revealed: Set<UUID> = []
    @State private var toast: ToastState?
    @State private var toastToken = 0
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Codes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: Binding(
                            get: { settings.accountSort },
                            set: { settings.accountSort = $0 })) {
                            ForEach(AccountSort.allCases) { sort in
                                Label(sort.rawValue, systemImage: sort.symbol).tag(sort)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .accessibilityLabel("Sort accounts")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search issuer or account")
            .toast($toast)
            .task { seedIfFirstLaunch() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if accounts.isEmpty {
            EmptyStateView(symbol: "shield.lefthalf.filled",
                           title: "No accounts yet",
                           message: "Add your first account by scanning a QR code, pasting a setup link, or entering a secret by hand. You can also load sample data from Settings.",
                           actionTitle: "Add your first account") {
                showAdd = true
            }
            .sheet(isPresented: $showAdd) {
                AddAccountSheet()
            }
        } else {
            VStack(spacing: 0) {
                if folders.count > 0 {
                    folderChips
                }
                listBody
            }
        }
    }

    private var folderChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", systemImage: "square.grid.2x2",
                           selected: selectedFolderID == nil) {
                    selectedFolderID = nil
                }
                ForEach(folders) { folder in
                    FilterChip(title: folder.name, systemImage: "folder",
                               selected: selectedFolderID == folder.id) {
                        selectedFolderID = (selectedFolderID == folder.id) ? nil : folder.id
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private var listBody: some View {
        let visible = filteredSorted
        if visible.isEmpty {
            EmptyStateView(symbol: "magnifyingglass",
                           title: "Nothing matches",
                           message: "No accounts match your search or selected folder. Try a different term or tap All.")
            Spacer()
        } else {
            // One timeline ticks every second; rows read `now` from the context.
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                List {
                    ForEach(visible) { account in
                        AccountRow(account: account,
                                   now: timeline.date,
                                   masked: settings.hideCodes && !revealed.contains(account.id),
                                   onCopy: { copy(account) },
                                   onToggleFavorite: { toggleFavorite(account) },
                                   onAdvanceHOTP: { advanceHOTP(account) },
                                   onReveal: { reveal(account) })
                            .listRowBackground(Theme.surface)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { delete(account) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button { toggleFavorite(account) } label: {
                                    Label("Favorite", systemImage: account.favorite ? "star.slash" : "star")
                                }
                                .tint(Theme.warn)
                            }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Filtering / sorting

    private var filteredSorted: [Account] {
        var result = accounts

        if let folderID = selectedFolderID {
            result = result.filter { $0.folder?.id == folderID }
        }

        let term = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !term.isEmpty {
            result = result.filter {
                $0.issuer.lowercased().contains(term) || $0.label.lowercased().contains(term)
            }
        }

        // Favorites always float to the top; then the chosen sort.
        switch settings.accountSort {
        case .manual:
            result.sort { lhs, rhs in
                if lhs.favorite != rhs.favorite { return lhs.favorite && !rhs.favorite }
                return lhs.sortIndex < rhs.sortIndex
            }
        case .issuer:
            result.sort { lhs, rhs in
                if lhs.favorite != rhs.favorite { return lhs.favorite && !rhs.favorite }
                return lhs.displayTitle.lowercased() < rhs.displayTitle.lowercased()
            }
        case .recent:
            result.sort { lhs, rhs in
                if lhs.favorite != rhs.favorite { return lhs.favorite && !rhs.favorite }
                return lhs.createdAt > rhs.createdAt
            }
        }
        return result
    }

    // MARK: - Actions

    private func copy(_ account: Account) {
        guard let secret = account.decodedSecret else {
            Haptics.error(settings.hapticsEnabled)
            showToast("Secret is invalid", symbol: "exclamationmark.triangle.fill")
            return
        }
        let code: String?
        switch account.type {
        case .totp:
            code = OTPGenerator.totp(secret: secret, digits: account.digits,
                                     period: account.period, algorithm: account.algorithm)
        case .hotp:
            code = OTPGenerator.hotp(secret: secret, counter: account.counter,
                                     digits: account.digits, algorithm: account.algorithm)
        }
        guard let code else {
            Haptics.error(settings.hapticsEnabled)
            showToast("Couldn't generate code", symbol: "exclamationmark.triangle.fill")
            return
        }
        UIPasteboard.general.string = code
        Haptics.success(settings.hapticsEnabled)
        showToast("Copied", symbol: "doc.on.doc.fill")
    }

    private func reveal(_ account: Account) {
        Haptics.tap(settings.hapticsEnabled)
        revealed.insert(account.id)
    }

    private func toggleFavorite(_ account: Account) {
        account.favorite.toggle()
        Haptics.tap(settings.hapticsEnabled)
        try? context.save()
    }

    private func advanceHOTP(_ account: Account) {
        account.counter = max(account.counter, 0) + 1
        Haptics.select(settings.hapticsEnabled)
        try? context.save()
        copy(account)
    }

    private func delete(_ account: Account) {
        context.delete(account)
        Haptics.warning(settings.hapticsEnabled)
        try? context.save()
    }

    private func showToast(_ message: String, symbol: String) {
        toastToken += 1
        toast = ToastState(message: message, symbol: symbol, token: toastToken)
    }

    private func seedIfFirstLaunch() {
        guard !didSeed else { return }
        didSeed = true
        if !SeedData.hasData(context: context) {
            SeedData.load(context: context, replaceExisting: false)
        }
    }
}
