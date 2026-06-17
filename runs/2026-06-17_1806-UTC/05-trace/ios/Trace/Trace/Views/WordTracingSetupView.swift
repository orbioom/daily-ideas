import SwiftUI

/// Pro feature: a parent types a short word/name; the child traces each letter
/// in sequence. Builds a glyph queue from the typed characters.
struct WordTracingSetupView: View {
    let profile: Profile

    @EnvironmentObject private var settings: AppSettings
    @State private var word = ""
    @State private var presentedFirst: Glyph?
    @State private var queue: [Glyph] = []

    private let maxLength = 10

    private var sanitized: String {
        String(word.prefix(maxLength))
    }

    private var resolvedGlyphs: [Glyph] {
        sanitized.compactMap { GlyphLibrary.glyph(forCharacter: $0) }
    }

    private var hasUntraceable: Bool {
        sanitized.contains { ch in
            !ch.isWhitespace && GlyphLibrary.glyph(forCharacter: ch) == nil
        }
    }

    var body: some View {
        ZStack {
            WarmBackground()
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "character.cursor.ibeam")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(Theme.berry)
                        .padding(.top, 8)
                        .accessibilityHidden(true)

                    Text("Type a word to trace")
                        .font(Theme.rounded(24, .bold))
                        .foregroundStyle(Theme.ink)

                    Text("Try your child's name or a favorite word. They'll trace each letter in order.")
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)

                    TextField("e.g. MIA", text: $word)
                        .font(Theme.rounded(28, .heavy))
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(16)
                        .card(cornerRadius: Theme.radiusMedium)
                        .accessibilityLabel("Word to trace")
                        .onChange(of: word) { _, newValue in
                            word = String(newValue.prefix(maxLength))
                        }

                    if !resolvedGlyphs.isEmpty {
                        previewRow
                    }

                    if hasUntraceable {
                        Label("Some characters can't be traced and will be skipped.", systemImage: "info.circle")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.warn)
                            .multilineTextAlignment(.center)
                    }

                    ChunkyButton(title: "Start tracing", systemImage: "play.fill") {
                        start()
                    }
                    .disabled(resolvedGlyphs.isEmpty)
                    .opacity(resolvedGlyphs.isEmpty ? 0.5 : 1)
                }
                .padding(20)
            }
        }
        .navigationTitle("Trace a Word")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $presentedFirst) { glyph in
            TracingCanvasView(glyph: glyph, profile: profile, queue: queue, onFinished: {})
        }
    }

    private var previewRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(resolvedGlyphs.enumerated()), id: \.offset) { _, g in
                    Text(g.display)
                        .font(Theme.rounded(28, .heavy))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 48, height: 48)
                        .card(cornerRadius: Theme.radiusSmall, fill: Theme.surface)
                }
            }
            .padding(.horizontal, 2)
        }
        .accessibilityLabel("Preview: \(resolvedGlyphs.count) letters to trace")
    }

    private func start() {
        let glyphs = resolvedGlyphs
        guard let first = glyphs.first else { return }
        queue = glyphs
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
        presentedFirst = first
    }
}
