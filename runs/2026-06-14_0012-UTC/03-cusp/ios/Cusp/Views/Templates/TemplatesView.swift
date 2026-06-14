import SwiftUI
import SwiftData

/// A gallery of common occasions. Tapping one opens the editor prefilled.
/// Also offers a "blank" event. Respects the free-tier event cap.
struct TemplatesView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var events: [CountdownEvent]

    @State private var pendingTemplate: EventTemplate?
    @State private var startBlank = false
    @State private var paywall: PaywallReason?

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    blankCard

                    SectionHeader(title: "Quick add", symbol: "sparkles")
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(EventTemplate.gallery) { template in
                            templateCard(template)
                        }
                    }

                    if !isPro {
                        freeFootnote
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Add Event")
            .sheet(item: $pendingTemplate) { template in
                EventEditorView(mode: .template(template, defaults: defaults()))
            }
            .sheet(isPresented: $startBlank) {
                EventEditorView(mode: .create(defaults: defaults()))
            }
            .sheet(item: $paywall) { reason in PaywallView(reason: reason) }
        }
    }

    private var blankCard: some View {
        Button {
            attemptCreate { startBlank = true }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.accentSoft).frame(width: 48, height: 48)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Blank event")
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Start from scratch")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func templateCard(_ template: EventTemplate) -> some View {
        Button {
            attemptCreate { pendingTemplate = template }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.22)).frame(width: 44, height: 44)
                    EventSymbolView(symbol: template.symbol, isEmoji: false,
                                    size: 22, color: CardTheme.from(template.themeTag).onGradient)
                }
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 3) {
                    Text(template.title)
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(CardTheme.from(template.themeTag).onGradient)
                    Text(template.subtitle)
                        .font(Theme.rounded(12))
                        .foregroundStyle(CardTheme.from(template.themeTag).onGradientSoft)
                        .lineLimit(2)
                }
                if template.repeatRule.repeats {
                    Label(template.repeatRule.title, systemImage: "repeat")
                        .font(Theme.rounded(10, .semibold))
                        .foregroundStyle(CardTheme.from(template.themeTag).onGradientSoft)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
            .padding(14)
            .background(CardTheme.from(template.themeTag).gradient,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(template.title). \(template.subtitle)")
    }

    private var freeFootnote: some View {
        let remaining = max(0, Pro.freeEventLimit - events.count)
        return HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(Theme.inkSoft)
            Text(remaining > 0
                 ? "\(remaining) of \(Pro.freeEventLimit) free events remaining."
                 : "You've used all \(Pro.freeEventLimit) free events. Unlock Pro for unlimited.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
        }
        .padding(14)
        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func defaults() -> EventEditorView.Defaults {
        EventEditorView.Defaults(kind: settings.defaultKind, themeTag: settings.defaultThemeTag)
    }

    private func attemptCreate(_ action: () -> Void) {
        if Pro.canCreate(currentCount: events.count, isPro: isPro) {
            Haptics.tap(enabled: settings.hapticsEnabled)
            action()
        } else {
            Haptics.warning(enabled: settings.hapticsEnabled)
            paywall = .eventLimit
        }
    }
}
