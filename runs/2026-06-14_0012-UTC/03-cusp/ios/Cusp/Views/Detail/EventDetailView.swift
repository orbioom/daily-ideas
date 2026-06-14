import SwiftUI
import SwiftData

/// Full-screen live countdown for a single event: a big ticking number inside a
/// progress ring, recurrence info, the note, a share card and edit/delete.
struct EventDetailView: View {
    @Bindable var event: CountdownEvent
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("isPro") private var isPro = false

    @State private var showingEditor = false
    @State private var confirmDelete = false
    @State private var paywall: PaywallReason?

    private var engine: CountdownEngine { settings.engine }
    private var theme: CardTheme { event.theme }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            detail(now: ctx.date)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(event.title.isEmpty ? "Event" : event.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .sheet(isPresented: $showingEditor) {
            EventEditorView(mode: .edit(event))
        }
        .sheet(item: $paywall) { reason in PaywallView(reason: reason) }
        .confirmationDialog("Delete this event?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    @ViewBuilder
    private func detail(now: Date) -> some View {
        let span = engine.span(for: event, now: now)
        let progress = engine.progress(for: event, now: now)
        let target = engine.effectiveDate(for: event, now: now)

        ScrollView {
            VStack(spacing: 22) {
                ringBlock(span: span, progress: progress)

                infoCard(target: target, span: span)

                if event.includeTime && !span.isToday {
                    liveTicker(span: span)
                }

                if !event.note.isEmpty {
                    noteCard
                }

                shareButton(now: now)

                actions
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
        }
    }

    private func ringBlock(span: CountdownEngine.Span, progress: Double) -> some View {
        ZStack {
            ProgressRing(
                progress: progress,
                lineWidth: 16,
                track: Theme.surfaceAlt,
                fill: AnyShapeStyle(theme.gradient),
                reduceMotion: reduceMotion
            )
            .frame(width: 240, height: 240)

            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(theme.dot.opacity(0.18)).frame(width: 56, height: 56)
                    EventSymbolView(symbol: event.symbol, isEmoji: event.symbolIsEmoji,
                                    size: 28, color: theme.dot)
                }
                if span.isToday {
                    Text("Today")
                        .font(Theme.rounded(44, .bold))
                        .foregroundStyle(Theme.ink)
                } else {
                    Text("\(span.totalDays)")
                        .font(Theme.rounded(58, .bold))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                        .contentTransition(reduceMotion ? .identity : .numericText())
                    Text(headlineUnitCaption(span))
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
                Text("\(Int(progress * 100))% there")
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ringAccessibility(span: span, progress: progress))
    }

    private func headlineUnitCaption(_ span: CountdownEngine.Span) -> String {
        let unit = span.totalDays == 1 ? "day" : "days"
        switch event.kind {
        case .until: return span.isFuture ? "\(unit) to go" : "\(unit) ago"
        case .since: return "\(unit) since"
        }
    }

    private func infoCard(target: Date, span: CountdownEngine.Span) -> some View {
        VStack(spacing: 0) {
            infoRow(icon: event.kind.symbol, label: event.kind.shortTitle,
                    value: event.kind.title)
            Divider().overlay(Theme.hairline)
            infoRow(icon: "calendar", label: "Date",
                    value: DateFmt.line(for: event, date: target))
            if event.repeatRule.repeats {
                Divider().overlay(Theme.hairline)
                infoRow(icon: event.repeatRule.symbol, label: "Repeats",
                        value: event.repeatRule.title)
                Divider().overlay(Theme.hairline)
                infoRow(icon: "arrow.uturn.forward", label: "Next",
                        value: DateFmt.full.string(from: target))
            }
        }
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(label)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 8)
            Text(value)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func liveTicker(span: CountdownEngine.Span) -> some View {
        HStack(spacing: 10) {
            tickerCell(span.days, "days")
            tickerCell(span.hours, "hrs")
            tickerCell(span.minutes, "min")
            tickerCell(span.seconds, "sec")
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(theme.gradient.opacity(0.92),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(span.days) days, \(span.hours) hours, \(span.minutes) minutes, \(span.seconds) seconds")
    }

    private func tickerCell(_ value: Int, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(Theme.rounded(26, .bold).monospacedDigit())
                .foregroundStyle(theme.onGradient)
                .contentTransition(reduceMotion ? .identity : .numericText())
            Text(label)
                .font(Theme.rounded(11, .medium))
                .foregroundStyle(theme.onGradientSoft)
        }
        .frame(maxWidth: .infinity)
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Note", symbol: "text.alignleft")
            Text(event.note)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func shareButton(now: Date) -> some View {
        if isPro {
            let card = ShareCard(event: event, now: now, engine: engine)
            if let image = renderShareImage(card) {
                ShareLink(item: image, preview: SharePreview(event.title.isEmpty ? "Cusp" : event.title, image: image)) {
                    shareLabel
                }
            } else {
                // Text fallback if rendering is unavailable.
                ShareLink(item: shareText(now: now)) { shareLabel }
            }
        } else {
            Button {
                Haptics.tap(enabled: settings.hapticsEnabled)
                paywall = .shareCard
            } label: {
                HStack {
                    shareLabel
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
    }

    private var shareLabel: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16, weight: .semibold))
            Text("Share card")
                .font(Theme.rounded(16, .semibold))
        }
        .foregroundStyle(Theme.accent)
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.tap(enabled: settings.hapticsEnabled)
                showingEditor = true
            } label: {
                Label("Edit", systemImage: "pencil")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.bad)
                    .frame(width: 54)
                    .padding(.vertical, 14)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Theme.hairline, lineWidth: 1)
                    )
            }
            .accessibilityLabel("Delete event")
        }
        .padding(.top, 4)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    event.pinned.toggle()
                    Haptics.tap(enabled: settings.hapticsEnabled)
                    try? context.save()
                } label: {
                    Label(event.pinned ? "Unpin" : "Pin",
                          systemImage: event.pinned ? "pin.slash" : "pin")
                }
                Button {
                    showingEditor = true
                } label: { Label("Edit", systemImage: "pencil") }
                Button(role: .destructive) {
                    confirmDelete = true
                } label: { Label("Delete", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("More options")
        }
    }

    // MARK: - Share helpers

    @MainActor
    private func renderShareImage(_ card: ShareCard) -> Image? {
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        if let ui = renderer.uiImage {
            return Image(uiImage: ui)
        }
        return nil
    }

    private func shareText(now: Date) -> String {
        let h = engine.headline(for: event, now: now)
        let title = event.title.isEmpty ? "My event" : event.title
        if engine.span(for: event, now: now).isToday {
            return "\(title) is today! — via Cusp"
        }
        return "\(h.value) \(h.unit) \(h.caption): \(title) — via Cusp"
    }

    private func performDelete() {
        Haptics.warning(enabled: settings.hapticsEnabled)
        context.delete(event)
        try? context.save()
        dismiss()
    }

    private func ringAccessibility(span: CountdownEngine.Span, progress: Double) -> String {
        let title = event.title.isEmpty ? "Event" : event.title
        if span.isToday { return "\(title), today. \(Int(progress * 100)) percent there." }
        let unit = span.totalDays == 1 ? "day" : "days"
        return "\(title), \(span.totalDays) \(unit) \(headlineUnitCaption(span)). \(Int(progress * 100)) percent there."
    }
}
