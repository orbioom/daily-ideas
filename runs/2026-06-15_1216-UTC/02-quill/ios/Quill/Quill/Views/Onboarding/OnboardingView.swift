import SwiftData
import SwiftUI

/// First-run onboarding. Explains the pen/eraser/templates and lets the user
/// create their first notebook. Gated by `@AppStorage("hasOnboarded")`.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0
    @State private var firstTitle = "My First Notebook"

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "books.vertical.fill",
            title: "Welcome to Quill",
            message: "A calm, fast handwriting notebook. Write and draw on real paper — no subscription, no clutter."
        ),
        OnboardingPage(
            icon: "pencil.tip.crop.circle",
            title: "Pen, highlighter & fountain",
            message: "Switch tools, colors, and stroke width from one clean toolbar. Undo, redo, and erase with a tap."
        ),
        OnboardingPage(
            icon: "square.grid.2x2",
            title: "Paper that fits",
            message: "Blank, ruled, grid, or dotted paper — choose per page. Your work autosaves as you go."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, p in
                    slide(p).tag(index)
                }
                createSlide.tag(pages.count)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(reduceMotion ? nil : .easeInOut, value: page)

            footer
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func slide(_ p: OnboardingPage) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: p.icon)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(p.title)
                .font(Theme.serif(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(p.message)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 36)
        .accessibilityElement(children: .combine)
    }

    private var createSlide: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "plus.rectangle.on.folder")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Create your first notebook")
                .font(Theme.serif(26, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("Give it a name. You can change the cover and paper any time.")
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            TextField("Notebook title", text: $firstTitle)
                .font(Theme.rounded(17))
                .multilineTextAlignment(.center)
                .padding(14)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 24)
                .accessibilityLabel("First notebook title")
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 36)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button {
                advance()
            } label: {
                Text(page == pages.count ? "Start Writing" : "Continue")
                    .font(Theme.rounded(17, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
            }
            .disabled(page == pages.count && firstTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 24)

            Button("Skip") {
                finish(createNotebook: false)
            }
            .font(Theme.rounded(15))
            .foregroundStyle(Theme.inkSoft)
            .opacity(page == pages.count ? 0 : 1)
            .disabled(page == pages.count)
        }
        .padding(.bottom, 24)
    }

    private func advance() {
        if page < pages.count {
            withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
        } else {
            finish(createNotebook: true)
        }
    }

    private func finish(createNotebook: Bool) {
        if createNotebook {
            let title = firstTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let notebook = Notebook(
                title: title.isEmpty ? "My First Notebook" : title,
                coverColorHex: "#4C63D8",
                defaultTemplate: settings.defaultTemplate
            )
            context.insert(notebook)
            let firstPage = Page(orderIndex: 0, template: notebook.defaultTemplate, notebook: notebook)
            context.insert(firstPage)
            try? context.save()
        }
        Haptics.success(settings.hapticsEnabled)
        hasOnboarded = true
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let message: String
}
