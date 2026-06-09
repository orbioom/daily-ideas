import SwiftUI
import SwiftData

/// Entry point for practice: a quick-start card plus the list of drills to launch.
struct PracticeHomeView: View {
    @Query(sort: [SortDescriptor(\Drill.sortIndex), SortDescriptor(\Drill.createdAt)])
    private var drills: [Drill]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if drills.isEmpty {
                    EmptyStateView(icon: "ear",
                                   title: "No drills yet",
                                   message: "Add a drill on the Drills tab, then come back to start training your ear.")
                        .glassCard()
                } else {
                    quickStart
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Choose a drill")
                        ForEach(drills) { drill in
                            NavigationLink {
                                PracticePlayerView(drill: drill)
                            } label: {
                                DrillRow(drill: drill)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Practice")
    }

    @ViewBuilder
    private var quickStart: some View {
        if let first = drills.first {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Quick start")
                Text(first.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Brand.text)
                Text(first.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                NavigationLink {
                    PracticePlayerView(drill: first)
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(InkButtonStyle())
            }
            .glassCard(padding: 18)
        }
    }
}

/// A tappable glass row summarizing a drill.
struct DrillRow: View {
    let drill: Drill
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: drill.type.symbol)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Brand.magic)
                .frame(width: 34)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(drill.name)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    if drill.isBuiltIn {
                        Text("Built-in")
                            .font(Brand.mono(10, weight: .medium))
                            .foregroundStyle(Brand.text3)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Brand.hairline, in: Capsule())
                    }
                }
                Text(drill.subtitle)
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(drill.name), \(drill.type.label)")
        .accessibilityHint(drill.subtitle)
    }
}
