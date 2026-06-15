import SwiftUI

/// Live reader typography & theme controls.
struct ReaderControlsSheet: View {
    @Binding var theme: ReaderTheme
    @Binding var font: ReaderFont
    @Binding var fontSize: Double
    @Binding var lineSpacing: Double
    var onLockedTheme: () -> Void
    var onLockedFont: () -> Void

    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    section("Theme") {
                        HStack(spacing: 10) {
                            ForEach(ReaderTheme.allCases) { t in
                                themeSwatch(t)
                            }
                        }
                    }

                    section("Font") {
                        HStack(spacing: 10) {
                            ForEach(ReaderFont.allCases) { f in
                                fontButton(f)
                            }
                        }
                    }

                    section("Text size") {
                        HStack(spacing: 14) {
                            Text("A").font(.system(size: 14))
                            Slider(value: $fontSize, in: 15...26, step: 1)
                                .tint(Theme.accent)
                                .accessibilityLabel("Text size")
                                .accessibilityValue("\(Int(fontSize)) points")
                            Text("A").font(.system(size: 24))
                        }
                        .foregroundStyle(Theme.inkSoft)
                    }

                    section("Line spacing") {
                        Slider(value: $lineSpacing, in: 2...16, step: 1)
                            .tint(Theme.accent)
                            .accessibilityLabel("Line spacing")
                            .accessibilityValue("\(Int(lineSpacing)) points")
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Reading options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.inkSoft)
            content()
        }
    }

    private func themeSwatch(_ t: ReaderTheme) -> some View {
        let locked = Pro.isThemeLocked(t, isPro: isPro)
        return Button {
            if locked {
                settings.haptic { Haptics.warning() }
                onLockedTheme()
            } else {
                settings.haptic { Haptics.selection() }
                theme = t
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(t.background)
                        .frame(height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(theme == t ? Theme.accent : Theme.hairline,
                                              lineWidth: theme == t ? 2.5 : 1)
                        )
                    Text("Aa")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundStyle(t.ink)
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.inkFaint)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(5)
                    }
                }
                Text(t.title)
                    .font(.caption)
                    .foregroundStyle(Theme.ink)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(t.title) theme\(locked ? ", Pro" : "")")
        .accessibilityAddTraits(theme == t ? [.isSelected, .isButton] : .isButton)
    }

    private func fontButton(_ f: ReaderFont) -> some View {
        let locked = Pro.isFontLocked(f, isPro: isPro)
        return Button {
            if locked {
                settings.haptic { Haptics.warning() }
                onLockedFont()
            } else {
                settings.haptic { Haptics.selection() }
                font = f
            }
        } label: {
            HStack(spacing: 4) {
                Text(f.title)
                    .font(.system(size: 15, weight: .medium, design: f.design))
                if locked {
                    Image(systemName: "lock.fill").font(.caption2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(font == f ? Theme.accent : Theme.surfaceAlt,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .foregroundStyle(font == f ? .white : Theme.ink)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(f.title) font\(locked ? ", Pro" : "")")
        .accessibilityAddTraits(font == f ? [.isSelected, .isButton] : .isButton)
    }
}
