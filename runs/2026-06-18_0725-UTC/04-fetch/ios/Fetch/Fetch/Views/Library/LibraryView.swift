import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @Query(sort: \CustomTrick.createdAt) private var customTricks: [CustomTrick]

    @State private var search = ""
    @State private var category: TrickCategory? = nil
    @State private var sessionTrickId: String?
    @State private var showAddCustom = false
    @State private var showPaywall = false

    private var activeDog: Dog? { DogManager.activeDog(from: dogs) }

    /// Catalog tricks projected, plus custom tricks as Tricks.
    private var allTricks: [Trick] {
        TrickCatalog.all + customTricks.map { $0.asTrick }
    }

    private var filtered: [Trick] {
        var items = allTricks
        if let category {
            items = items.filter { $0.category == category }
        }
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            items = items.filter {
                $0.name.lowercased().contains(q) || $0.summary.lowercased().contains(q)
            }
        }
        return items.sorted { a, b in
            if a.difficulty != b.difficulty { return a.difficulty < b.difficulty }
            return a.name < b.name
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    categoryBar
                    if filtered.isEmpty {
                        EmptyStateView(
                            systemImage: "magnifyingglass",
                            title: "No tricks found",
                            message: "Try a different search or category filter."
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { trick in
                                    NavigationLink {
                                        TrickDetailView(trick: trick) { startSession(trick.id) }
                                    } label: {
                                        TrickCard(
                                            trick: trick,
                                            status: activeDog.map { ProgressEngine.status(for: $0, trickId: trick.id) } ?? .notStarted
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 28)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .searchable(text: $search, prompt: "Search tricks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if isPro { showAddCustom = true } else { showPaywall = true }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add custom trick")
                }
            }
            .sheet(isPresented: $showAddCustom) {
                CustomTrickEditor()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .fullScreenCover(item: Binding(
                get: { sessionTrickId.map { LibrarySessionTarget(trickId: $0) } },
                set: { sessionTrickId = $0?.trickId }
            )) { target in
                if let dog = activeDog {
                    SessionPlayerView(dog: dog, trickId: target.trickId)
                } else {
                    NoDogSheet()
                }
            }
        }
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(title: "All", icon: "square.grid.2x2.fill", selected: category == nil) {
                    category = nil
                }
                ForEach(TrickCategory.allCases) { cat in
                    CategoryChip(title: cat.rawValue, icon: cat.icon, selected: category == cat) {
                        category = (category == cat) ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func startSession(_ trickId: String) {
        guard activeDog != nil else { return }
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
        sessionTrickId = trickId
    }
}

private struct LibrarySessionTarget: Identifiable {
    let trickId: String
    var id: String { trickId }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(Theme.rounded(14, .semibold))
            }
            .foregroundStyle(selected ? .white : Theme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(selected ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.surface))
            )
            .overlay(
                Capsule().stroke(selected ? Color.clear : Theme.hairline, lineWidth: 1)
            )
        }
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

struct TrickCard: View {
    let trick: Trick
    let status: TrickStatus
    var body: some View {
        Card {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(trick.difficulty.color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: trick.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(trick.difficulty.color)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(trick.name)
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(trick.summary)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        Chip(text: trick.difficulty.label, color: trick.difficulty.color)
                        if status != .notStarted {
                            StatusBadge(status: status, compact: true)
                        }
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(trick.name), \(trick.difficulty.label), \(status == .notStarted ? "not started" : status.rawValue)")
    }
}

/// Shown when a session is requested with no dog available.
struct NoDogSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 18) {
                EmptyStateView(
                    systemImage: "pawprint.circle",
                    title: "Add a dog first",
                    message: "Head to the Dogs tab to add a dog, then start a session."
                )
                Button("Close") { dismiss() }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.horizontal, 40)
            }
        }
    }
}
