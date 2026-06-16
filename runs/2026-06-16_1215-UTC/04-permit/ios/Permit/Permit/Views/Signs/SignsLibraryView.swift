import SwiftUI

struct SignsLibraryView: View {
    @EnvironmentObject private var pro: ProStore
    @State private var search = ""
    @State private var showPaywall = false

    private var filtered: [RoadSign] {
        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return SignLibrary.all }
        return SignLibrary.all.filter {
            $0.name.lowercased().contains(trimmed) || $0.meaning.lowercased().contains(trimmed)
        }
    }

    private var grouped: [(kind: SignKind, signs: [RoadSign])] {
        SignKind.allCases.compactMap { kind in
            let items = filtered.filter { $0.kind == kind }
            return items.isEmpty ? nil : (kind, items)
        }
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if !pro.isPro {
                    lockedView
                } else if filtered.isEmpty {
                    EmptyStateView(systemImage: "magnifyingglass",
                                   title: "No matching signs",
                                   message: "Try a different word, like 'stop', 'school' or 'merge'.")
                } else {
                    libraryGrid
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Road Signs")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var libraryGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(grouped, id: \.kind) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group.kind.rawValue + " signs")
                            .font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(group.signs) { sign in
                                NavigationLink(value: sign) {
                                    signCell(sign)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .searchable(text: $search, prompt: "Search signs")
        .navigationDestination(for: RoadSign.self) { sign in
            SignDetailView(sign: sign)
        }
    }

    private func signCell(_ sign: RoadSign) -> some View {
        Card(padding: 12) {
            VStack(spacing: 8) {
                SignView(sign: sign, size: 88)
                Text(sign.name)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(sign.name) sign")
        .accessibilityHint("Opens details and a study tip")
    }

    private var lockedView: some View {
        ScrollView {
            VStack(spacing: 16) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(SignLibrary.all.prefix(4))) { sign in
                        Card(padding: 12) {
                            VStack(spacing: 8) {
                                SignView(sign: sign, size: 88)
                                Text(sign.name).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
                            }
                        }
                    }
                }
                .opacity(0.5)
                .allowsHitTesting(false)

                VStack(spacing: 12) {
                    Image(systemName: "signpost.right.fill")
                        .font(.system(size: 40)).foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Text("Signs library is a Pro feature")
                        .font(Theme.rounded(19, .bold)).foregroundStyle(Theme.ink)
                    Text("Study all \(SignLibrary.all.count) common road signs — drawn, named and explained — with Permit Pro.")
                        .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                    PrimaryButton(title: "Unlock Permit Pro", systemImage: "crown.fill") {
                        showPaywall = true
                    }
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
    }
}
