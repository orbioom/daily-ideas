import SwiftUI
import SwiftData

/// Patterns tab: browse all techniques grouped by style, filter, favorite, and
/// drill into a detail screen that launches a session.
struct PatternsView: View {
    var body: some View {
        NavigationStack {
            PatternListContent()
                .navigationTitle("Techniques")
        }
    }
}

/// The reusable list body (no NavigationStack of its own) so it can be embedded
/// or pushed from other stacks without double-nesting.
struct PatternListContent: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsRows: [AppSettings]

    @State private var filter: BreathStyle? = nil

    private var settings: AppSettings? { settingsRows.first }

    private var styles: [BreathStyle] {
        if let filter { return [filter] }
        return BreathStyle.allCases
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                filterChips
                ForEach(styles) { style in
                    let patterns = PatternLibrary.patterns(style: style)
                    if !patterns.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            SectionHeader(title: style.displayName)
                            ForEach(patterns) { pattern in
                                NavigationLink {
                                    PatternDetailView(pattern: pattern)
                                } label: {
                                    PatternCard(pattern: pattern,
                                                isFavorite: settings?.isFavorite(pattern.id) ?? false) {
                                        toggleFavorite(pattern)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.md)
        }
        .emberScreenBackground()
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                chip(title: "All", active: filter == nil) { filter = nil }
                ForEach(BreathStyle.allCases) { style in
                    chip(title: style.displayName, active: filter == style, tint: style.accent) {
                        filter = (filter == style) ? nil : style
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(title: String, active: Bool, tint: Color = Theme.accent, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.tap()
            withAnimation(.easeInOut(duration: 0.2)) { action() }
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(active ? tint.opacity(0.22) : Theme.card)
                .foregroundStyle(active ? Theme.textPrimary : Theme.textSecondary)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(active ? tint : Theme.textSecondary.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? [.isSelected] : [])
    }

    private func toggleFavorite(_ pattern: BreathPattern) {
        guard let settings else { return }
        Haptics.shared.tap()
        settings.toggleFavorite(pattern.id)
        try? context.save()
    }
}

#Preview {
    PatternsView()
        .previewModelContainer()
}
