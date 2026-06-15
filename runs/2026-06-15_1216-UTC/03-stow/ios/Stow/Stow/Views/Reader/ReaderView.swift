import SwiftUI
import SwiftData

struct ReaderView: View {
    @Bindable var article: Article

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var theme: ReaderTheme = .sepia
    @State private var font: ReaderFont = .serif
    @State private var fontSize: Double = 19
    @State private var lineSpacing: Double = 8

    @State private var showControls = false
    @State private var showTagEditor = false
    @State private var showPaywall = false
    @State private var paywallReason: PaywallReason = .general
    @State private var contentHeight: CGFloat = 1
    @State private var selectedSnippet: String?
    @State private var didLoadPrefs = false

    private var blocks: [ContentBlock] { article.blocks }

    var body: some View {
        ZStack(alignment: .top) {
            theme.background.ignoresSafeArea()
            readerScroll
            progressBarOverlay
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .toolbarBackground(theme.background, for: .navigationBar)
        .toolbarColorScheme(theme.isDark ? .dark : .light, for: .navigationBar)
        .sheet(isPresented: $showControls) {
            ReaderControlsSheet(
                theme: $theme, font: $font, fontSize: $fontSize, lineSpacing: $lineSpacing,
                onLockedTheme: { presentPaywall(.lockedTheme) },
                onLockedFont: { presentPaywall(.lockedFont) }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showTagEditor) {
            TagEditorSheet(article: article)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(reason: paywallReason)
        }
        .confirmationDialog("Highlight", isPresented: highlightDialogBinding, titleVisibility: .visible) {
            Button("Save highlight") { saveHighlight() }
            Button("Cancel", role: .cancel) { selectedSnippet = nil }
        } message: {
            Text(selectedSnippet ?? "")
        }
        .onAppear(perform: loadPrefsOnce)
        .onDisappear(perform: persistProgress)
    }

    // MARK: Scroll content

    private var readerScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 18)

                ForEach(blocks) { block in
                    blockView(block)
                        .padding(.bottom, block.kind == .heading ? 6 : 18)
                }

                footerActions
                    .padding(.top, 18)
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 60)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: ContentHeightKey.self, value: geo.size.height)
                }
            )
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetKey.self,
                        value: geo.frame(in: .named("readerScroll")).minY
                    )
                }
            )
        }
        .coordinateSpace(name: "readerScroll")
        .onPreferenceChange(ContentHeightKey.self) { contentHeight = max(1, $0) }
        .onPreferenceChange(ScrollOffsetKey.self) { minY in
            updateProgress(minY: minY)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                if !article.siteName.isEmpty {
                    Text(article.siteName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
                Text("· \(article.estMinutes) min · \(article.wordCount) words")
                    .font(.caption)
                    .foregroundStyle(theme.inkSoft)
            }
            Text(article.title)
                .font(.system(size: fontSize + 11, weight: .bold, design: font.design))
                .foregroundStyle(theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if !article.byline.isEmpty {
                Text("By \(article.byline)")
                    .font(.system(size: fontSize - 2, design: font.design))
                    .foregroundStyle(theme.inkSoft)
            }
            Divider().overlay(theme.inkSoft.opacity(0.3))
        }
    }

    private func blockView(_ block: ContentBlock) -> some View {
        Group {
            switch block.kind {
            case .heading:
                Text(block.text)
                    .font(.system(size: fontSize + 4, weight: .semibold, design: font.design))
                    .foregroundStyle(theme.ink)
                    .padding(.top, 10)
            case .paragraph:
                Text(block.text)
                    .font(.system(size: fontSize, design: font.design))
                    .foregroundStyle(theme.ink)
                    .lineSpacing(lineSpacing)
                    .textSelection(.enabled)
                    .contextMenu {
                        Button {
                            requestHighlight(block.text)
                        } label: {
                            Label("Highlight paragraph", systemImage: "highlighter")
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var footerActions: some View {
        VStack(spacing: 14) {
            Divider().overlay(theme.inkSoft.opacity(0.3))
            HStack(spacing: 18) {
                actionPill(article.isFavorite ? "Favorited" : "Favorite",
                           icon: article.isFavorite ? "heart.fill" : "heart") {
                    toggleFavorite()
                }
                actionPill(article.isArchived ? "Unarchive" : "Mark read",
                           icon: article.isArchived ? "tray.and.arrow.up" : "checkmark.circle") {
                    toggleArchive()
                }
            }
            Text("Saved \(article.savedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(theme.inkSoft)
        }
    }

    private func actionPill(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(theme.ink.opacity(0.07), in: Capsule())
                .foregroundStyle(theme.ink)
        }
        .accessibilityLabel(title)
    }

    // MARK: Progress overlay

    private var progressBarOverlay: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Theme.accent)
                .frame(width: max(0, min(1, article.readingProgress)) * geo.size.width, height: 3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 3)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button { showTagEditor = true } label: {
                    Label("Tags", systemImage: "tag")
                }
                Button { exportArticle() } label: {
                    Label("Export text", systemImage: "square.and.arrow.up")
                }
                ShareLink(item: shareText) {
                    Label("Share", systemImage: "paperplane")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("More actions")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showControls = true } label: {
                Image(systemName: "textformat.size")
            }
            .accessibilityLabel("Reading options")
        }
    }

    private var shareText: String {
        "\(article.title)\n\n\(article.plainText)\n\n— via Stow"
    }

    // MARK: Highlight handling

    private var highlightDialogBinding: Binding<Bool> {
        Binding(
            get: { selectedSnippet != nil },
            set: { if !$0 { selectedSnippet = nil } }
        )
    }

    private func requestHighlight(_ text: String) {
        guard isPro else { presentPaywall(.highlights); return }
        selectedSnippet = text
    }

    private func saveHighlight() {
        guard let snippet = selectedSnippet, !snippet.isEmpty else { return }
        let highlight = Highlight(text: snippet, article: article)
        context.insert(highlight)
        try? context.save()
        settings.haptic { Haptics.success() }
        selectedSnippet = nil
    }

    // MARK: Progress

    private func updateProgress(minY: CGFloat) {
        // minY starts near 0 and goes negative as we scroll down.
        let viewport = UIScreen.main.bounds.height
        let scrollable = max(1, contentHeight - viewport)
        let scrolled = max(0, -minY)
        let p = min(1, scrolled / scrollable)
        if abs(p - article.readingProgress) > 0.01 {
            article.readingProgress = p
        }
    }

    private func persistProgress() {
        try? context.save()
    }

    // MARK: Actions

    private func toggleFavorite() {
        settings.haptic { Haptics.tap() }
        article.isFavorite.toggle()
        try? context.save()
    }

    private func toggleArchive() {
        settings.haptic { Haptics.tap() }
        article.isArchived.toggle()
        try? context.save()
        if article.isArchived { dismiss() }
    }

    private func exportArticle() {
        guard isPro else { presentPaywall(.export); return }
        UIPasteboard.general.string = shareText
        settings.haptic { Haptics.success() }
    }

    private func presentPaywall(_ reason: PaywallReason) {
        paywallReason = reason
        showPaywall = true
    }

    // MARK: Prefs

    private func loadPrefsOnce() {
        guard !didLoadPrefs else { return }
        didLoadPrefs = true
        // Start from user's defaults, downgrading locked picks for free users.
        var t = settings.defaultReaderTheme
        if Pro.isThemeLocked(t, isPro: isPro) { t = .sepia }
        var f = settings.defaultReaderFont
        if Pro.isFontLocked(f, isPro: isPro) { f = .serif }
        theme = t
        font = f
        // Respect system text size as a floor while honoring the saved size.
        fontSize = max(settings.readerFontSize, 15)
        lineSpacing = settings.readerLineSpacing
    }
}

// MARK: - Preference keys

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 1
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
