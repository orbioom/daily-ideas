import SwiftUI
import SwiftData

/// A gallery of starter templates. Choosing one builds a pre-populated map and
/// opens it in the workspace.
struct TemplatesView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @Query private var maps: [MindMap]

    @State private var path: [UUID] = []
    @State private var showPaywall = false

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Start from a template")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .padding(.horizontal, 16)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(MapTemplates.all) { template in
                            Button {
                                choose(template)
                            } label: {
                                TemplateCard(template: template)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Templates")
            .navigationDestination(for: UUID.self) { id in
                if let map = maps.first(where: { $0.id == id }) {
                    MapWorkspaceView(map: map)
                } else {
                    EmptyStateView(symbol: "questionmark.folder",
                                   title: "Map unavailable",
                                   message: "This template map could not be opened.")
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func choose(_ template: MapTemplate) {
        guard ProLimits.canCreateMap(currentCount: maps.count, isPro: isPro) else {
            Haptics.warning()
            showPaywall = true
            return
        }
        // If the template's theme is Pro-only and user is free, fall back to a free theme.
        var t = template
        if !isPro && !template.theme.isFree {
            t = MapTemplate(id: template.id, title: template.title, subtitle: template.subtitle,
                            symbol: template.symbol, theme: .mist, spec: template.spec)
        }
        let map = t.build(in: context)
        Haptics.success()
        path.append(map.id)
    }
}

private struct TemplateCard: View {
    let template: MapTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(template.theme.swatch.opacity(0.25))
                    .frame(height: 70)
                Image(systemName: template.symbol)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(template.theme.swatch)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(template.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(template.subtitle)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(template.title) template. \(template.subtitle)")
        .accessibilityAddTraits(.isButton)
    }
}
