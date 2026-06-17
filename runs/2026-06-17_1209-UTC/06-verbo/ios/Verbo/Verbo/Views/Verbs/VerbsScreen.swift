import SwiftUI

/// Browse the verb catalog with filters and search.
struct VerbsScreen: View {
    @AppStorage(Prefs.isPro) private var isPro = false
    @AppStorage(Prefs.frenchEnabled) private var frenchEnabled = false

    @State private var language: Language = .spanish
    @State private var search = ""
    @State private var groupFilter: VerbGroup?
    @State private var irregularOnly = false
    @State private var paywallReason: PaywallReason?

    private var availableLanguages: [Language] {
        Language.allCases.filter { $0 == .spanish || (frenchEnabled && isPro) }
    }

    private var verbs: [Verb] {
        var list = VerbCatalog.verbs(for: language, proUnlocked: isPro)
        if let groupFilter {
            list = list.filter { $0.group == groupFilter }
        }
        if irregularOnly {
            list = list.filter { $0.isIrregular }
        }
        let q = search.trimmingCharacters(in: .whitespaces).foldedForComparison
        if !q.isEmpty {
            list = list.filter {
                $0.infinitive.foldedForComparison.contains(q) ||
                $0.meaning.foldedForComparison.contains(q)
            }
        }
        return list
    }

    private var availableGroups: [VerbGroup] {
        language == .spanish ? [.ar, .er, .ir] : [.er, .ir, .re]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    filters
                    if verbs.isEmpty {
                        EmptyStateView(symbol: "magnifyingglass",
                                       title: "No verbs found",
                                       message: "Try clearing the search or filters.")
                    } else {
                        List {
                            ForEach(verbs) { verb in
                                NavigationLink(value: verb) {
                                    VerbRow(verb: verb)
                                }
                                .listRowBackground(Theme.surface)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Verbs")
            .searchable(text: $search, prompt: "Search verbs or meanings")
            .navigationDestination(for: Verb.self) { verb in
                VerbDetailView(verb: verb)
            }
            .toolbar {
                if !isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { paywallReason = .allVerbs } label: {
                            Label("Pro", systemImage: "crown.fill")
                                .font(Theme.rounded(13, .semibold))
                        }
                    }
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private var filters: some View {
        VStack(spacing: 10) {
            if availableLanguages.count > 1 {
                Picker("Language", selection: $language) {
                    ForEach(availableLanguages) { Text("\($0.flag) \($0.displayName)").tag($0) }
                }
                .pickerStyle(.segmented)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip("All", selected: groupFilter == nil) { groupFilter = nil }
                    ForEach(availableGroups) { g in
                        chip(g.displayName, selected: groupFilter == g) {
                            groupFilter = groupFilter == g ? nil : g
                        }
                    }
                    chip("Irregular", selected: irregularOnly, symbol: "bolt") {
                        irregularOnly.toggle()
                    }
                }
                .padding(.horizontal, 2)
            }
            if !isPro && language == .spanish {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill").font(.system(size: 11))
                    Text("Free tier shows 40 verbs. Unlock all with Pro.")
                        .font(Theme.rounded(12))
                }
                .foregroundStyle(Theme.inkFaint)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func chip(_ title: String, selected: Bool, symbol: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let symbol { Image(systemName: symbol).font(.system(size: 10, weight: .bold)) }
                Text(title).font(Theme.rounded(13, .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Capsule().fill(selected ? Theme.accent : Theme.surfaceAlt))
            .foregroundStyle(selected ? .white : Theme.inkSoft)
        }
    }
}

/// One verb row in the catalog list.
struct VerbRow: View {
    let verb: Verb

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(verb.infinitive)
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(verb.meaning)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            if verb.isIrregular {
                Pill(text: "irregular", systemImage: "bolt.fill", tint: Theme.bad)
            }
            Pill(text: verb.group.displayName, tint: Theme.accent)
        }
        .padding(.vertical, 4)
    }
}
