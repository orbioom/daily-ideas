import SwiftUI
import SwiftData

struct GlyphGridView: View {
    let set: GlyphSetKind
    let profile: Profile

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context

    @State private var practiceQueue: [Glyph] = []
    @State private var presentedGlyph: Glyph?
    // Bump to force the grid stars to recompute after returning from tracing.
    @State private var refreshToken = 0

    private var glyphs: [Glyph] { GlyphLibrary.glyphs(for: set) }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)

    var body: some View {
        ZStack {
            WarmBackground()
            ScrollView {
                VStack(spacing: 16) {
                    practiceButton
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(glyphs) { glyph in
                            GlyphCell(
                                glyph: glyph,
                                stars: ProgressService.bestStars(profileID: profile.id, glyphKey: glyph.key, context: context)
                            )
                            .id("\(glyph.key)-\(refreshToken)")
                            .onTapGesture {
                                Haptics.selection(enabled: settings.hapticsEnabled)
                                practiceQueue = [glyph]
                                presentedGlyph = glyph
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(set.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $presentedGlyph) { glyph in
            TracingCanvasView(
                glyph: glyph,
                profile: profile,
                queue: practiceQueue,
                onFinished: { refreshToken += 1 }
            )
        }
    }

    private var practiceButton: some View {
        ChunkyButton(title: "Practice in order", systemImage: "play.fill") {
            Haptics.impact(.light, enabled: settings.hapticsEnabled)
            practiceQueue = glyphs
            presentedGlyph = glyphs.first
        }
        .disabled(glyphs.isEmpty)
    }
}

private struct GlyphCell: View {
    let glyph: Glyph
    let stars: Int

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous)
                    .fill(Theme.surface)
                if glyph.set == .shapes {
                    // Show the actual traceable outline for shapes.
                    GlyphPreview(glyph: glyph, lineWidth: 4, color: Theme.ink)
                        .padding(10)
                } else {
                    Text(glyph.display)
                        .font(Theme.rounded(34, .heavy))
                        .foregroundStyle(Theme.ink)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(height: 64)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous)
                    .strokeBorder(stars >= 3 ? Theme.star : Theme.hairline, lineWidth: stars >= 3 ? 2.5 : 1)
            )
            StarRatingView(count: stars, size: 11)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(glyph.label), \(Formatters.starsPhrase(stars))")
        .accessibilityHint("Opens tracing")
        .accessibilityAddTraits(.isButton)
    }
}
