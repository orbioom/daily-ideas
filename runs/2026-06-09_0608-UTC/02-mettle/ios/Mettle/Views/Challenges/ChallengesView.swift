import SwiftUI
import SwiftData

struct ChallengesView: View {
    @Query(sort: \Challenge.sortIndex, order: .forward)
    private var challenges: [Challenge]

    @State private var showEditor = false

    private var builtIns: [Challenge] { challenges.filter { $0.isBuiltIn } }
    private var customs: [Challenge] { challenges.filter { !$0.isBuiltIn } }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if challenges.isEmpty {
                    EmptyStateView(
                        icon: "trophy",
                        title: "No programs yet",
                        message: "Tap the + to build your own challenge."
                    )
                    .padding(.top, 40)
                } else {
                    if !builtIns.isEmpty {
                        section(title: "Programs", items: builtIns)
                    }
                    section(title: "Your challenges", items: customs, showEmpty: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Challenges")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEditor = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create a custom challenge")
            }
        }
        .navigationDestination(for: Challenge.self) { ch in
            ChallengeDetailView(challenge: ch)
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                ChallengeEditorView(challenge: nil)
            }
        }
    }

    @ViewBuilder
    private func section(title: String, items: [Challenge], showEmpty: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: title)
            if items.isEmpty && showEmpty {
                Text("Build your own program with the + button.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
            } else {
                ForEach(items) { ch in
                    NavigationLink(value: ch) {
                        ChallengeCard(challenge: ch)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ChallengeCard: View {
    let challenge: Challenge

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(challenge.name)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                Spacer(minLength: 0)
                if challenge.isActive {
                    Pill(text: "Active", tint: Brand.live, filled: true)
                }
                Pill(text: challenge.modeLabel,
                     tint: challenge.hardMode ? Brand.danger : Brand.info)
            }
            if !challenge.summary.isEmpty {
                Text(challenge.summary)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .lineLimit(2)
            }
            HStack(spacing: 16) {
                Label("\(challenge.durationDays) days", systemImage: "calendar")
                Label("\(challenge.orderedTasks.count) tasks", systemImage: "checklist")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(Brand.text3)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(challenge.name), \(challenge.durationDays) days, \(challenge.orderedTasks.count) tasks, \(challenge.modeLabel) mode\(challenge.isActive ? ", active" : "")")
    }
}
